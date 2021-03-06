//*****************************************************************************
//
// Shader compiling subsystem
//
//*****************************************************************************

module engine.gpu.compile;

//-----------------------------------------------------------------------------

import engine.gpu.util;
import engine.gpu.shader;
import engine.game: screen;
import std.string: toStringz, countchars;
import std.algorithm: map;
import std.regex;

alias to = engine.util.to;

/*-----------------------------------------------------------------------------

For further shader development, it is necessary to have a system for:

1) Ensure that you can make group of shaders with compatible interface
   to CPU side: especially that VAOs are interchangeable

2) "Pluggability" - reuse vertex shader with different fragment shaders,
   or reuse parts of specific shader to implement another one.

One important design principle is that error reporting works correctly.
Otherwise it can be awfully hard to figure out what went wrong. Sadly, there
are several problems with this:

1) Not all drivers report source file number correctly (my OpenGL driver
   seems to concatenate source strings internally, and thus it always
   reports "0" and concatenated string's line number)
   
2) Error message format is driver-specific

We can't let this stop us. For our purposes, it is probably best to concatenate
source strings at CPU side and form some sort of lookup table to find the file
name where the line was read.

For vendor-specific error reports we can't do much, just work to get the line
number from the message.

-----------------------------------------------------------------------------*/

class ShaderCompileError : Exception
{
    this(string msg) { super(msg); }
    this(char[] msg) { super(to!string(msg)); }
}

//*****************************************************************************
//
// Compiling a GPU program
//
//*****************************************************************************

GLuint CompileProgram(
    Shader.Family family,
    string vs_source,
    string gs_source,
    string fs_source
)
{
    //-------------------------------------------------------------------------
    // Create program, and bind all the attributes from family
    // to specific locations.
    //-------------------------------------------------------------------------
    
    GLuint programID = checkgl!glCreateProgram();

    foreach(name, param; family.attributes)
    {
        checkgl!glBindAttribLocation(programID, param.location, toStringz(name));
    }
    
    //-------------------------------------------------------------------------

    GLuint[] shaders;
    
    if(vs_source) shaders ~= compileShader(GL_VERTEX_SHADER,   vs_source);
    if(gs_source) shaders ~= compileShader(GL_GEOMETRY_SHADER, gs_source);
    if(fs_source) shaders ~= compileShader(GL_FRAGMENT_SHADER, fs_source);

    //-------------------------------------------------------------------------

    foreach(shaderID; shaders) checkgl!glAttachShader(programID, shaderID);
    checkgl!glLinkProgram(programID);

    //-------------------------------------------------------------------------

    foreach(shaderID; shaders)
    {
        checkgl!glDetachShader(programID, shaderID);
        checkgl!glDeleteShader(shaderID);
    }

    //-------------------------------------------------------------------------

    auto msg = getProgramInfoLog(programID);
    if(msg.length) Log << msg;

    ERRORIF(!getProgram!bool(programID, GL_LINK_STATUS), "Program link failed");

    //-------------------------------------------------------------------------

    debug validate(programID);

    //-------------------------------------------------------------------------

    return programID;
}

//*****************************************************************************
//
// Compiling shader
//
//*****************************************************************************

GLuint compileShader(GLenum shadertype, string[] srcs...)
{
    const string[GLenum] header = [
        GL_VERTEX_SHADER:   "#define VERTEX_SHADER\n",
        GL_GEOMETRY_SHADER: "#define GEOMETRY_SHADER\n",
        GL_FRAGMENT_SHADER: "#define FRAGMENT_SHADER\n"
    ];

    const(char)*[] source = [
        toStringz("#version 330\n"),
        toStringz(header[shadertype])
    ];

    //-------------------------------------------------------------------------
    // Construct string array from sources. At the top of the source we put
    // some built-ins. We allow null filenames for missing optional parts.
    //-------------------------------------------------------------------------

    foreach(src; srcs) if(src) source ~= toStringz(src);

    //-------------------------------------------------------------------------

    auto shaderID = checkgl!glCreateShader(shadertype);

    checkgl!glShaderSource(shaderID, cast(int)source.length, source.ptr, null);
    checkgl!glCompileShader(shaderID);

    auto msg = getShaderInfoLog(shaderID);
    if(msg.length) Log << msg;

    ERRORIF(!getShader!bool(shaderID, GL_COMPILE_STATUS), "Shader compile failed.");
    
    return shaderID;

/*
    //debug writeln(getShaderSource(shaderID));
    auto errorat = new Location(msg);

    foreach(i, content; source)
    {
        size_t lines = countchars(to!string(content), "\n");
        if(errorat.line <= lines) {
            errorat.filename = files[i];
            break;
        }
        errorat.line -= lines;
    }

    const string[uint] phase = [
        GL_VERTEX_SHADER: "Vertex Shader",
        GL_FRAGMENT_SHADER: "Fragment Shader"
    ];

    throw new ShaderCompileError(format(
        "\nCompiling %s: %s:%u:%s",
        phase[shadertype],
        errorat.filename,
        errorat.line,
        errorat.msg)
    );
/*/
/**/
}

//*****************************************************************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// Getting source ID and line number from error message. TODO: Determine
// video driver, and write driver-specific regexes.
//-----------------------------------------------------------------------------

private class Location
{
    size_t fileid, line;
    string filename;
    string msg;

    this(string msg)
    {
        auto re = regex(
            r"^\s*(?P<fileid>\d+)\:(?P<line>\d+)\((?P<column>\d+)\)\:"
        );
        auto c = matchFirst(msg, re);

        this.fileid = to!size_t(c["fileid"]);
        this.line = to!size_t(c["line"]);
        this.msg = c.post();
        this.filename = "<unknown>";
    }
}

//-----------------------------------------------------------------------------
// Querying compiled shader program parameters from GPU
//-----------------------------------------------------------------------------

private auto getShader(T)(GLuint shaderID, GLenum name)
{
    GLint result;
    checkgl!glGetShaderiv(shaderID, name, &result);
    return cast(T)result;
}

debug private string getShaderSource(GLuint shaderID)
{
    int src_length = getShader!int(shaderID, GL_SHADER_SOURCE_LENGTH);

    char[] buffer = new char[src_length];
    checkgl!glGetShaderSource(shaderID, src_length, null, buffer.ptr);
    return to!string(buffer);
}

private string getShaderInfoLog(GLuint shaderID)
{
    int log_length = getShader!int(shaderID, GL_INFO_LOG_LENGTH);

    if(log_length)
    {
        char[] buffer = new char[log_length];
        checkgl!glGetShaderInfoLog(shaderID, log_length, null, buffer.ptr);
        return to!string(buffer.ptr);
    }
    return "";
}

//-----------------------------------------------------------------------------
// Querying compiled program parameters from GPU
//-----------------------------------------------------------------------------

private auto getProgram(T)(GLuint programID, GLenum name)
{
    GLint result;
    checkgl!glGetProgramiv(programID, name, &result);
    return cast(T)result;
}

private string getProgramInfoLog(GLuint programID)
{
    int log_length = getProgram!int(programID, GL_INFO_LOG_LENGTH);

    if(log_length)
    {
        char[] buffer = new char[log_length];
        glGetProgramInfoLog(programID, log_length, null, buffer.ptr);
        return to!string(buffer.ptr);
    }
    return "";
}

//-----------------------------------------------------------------------------
// Program validation
//-----------------------------------------------------------------------------

private void validate(GLuint programID)
{
    checkgl!glValidateProgram(programID);
    bool status = getProgram!bool(programID, GL_VALIDATE_STATUS);

    //writeln("GLSL: Validate program ", programID, ": ", status ? "OK" : "Fail");

    //if(!status) writeln("- Message: ", getProgramInfoLog(programID));
}

