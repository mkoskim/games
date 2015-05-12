//*****************************************************************************
//
// Shader compiling subsystem
//
//*****************************************************************************

module engine.render.shaders.gpucompile;

//-----------------------------------------------------------------------------

import engine.render.util;
import blob = engine.blob;

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

1) Not all drivers report source file number correctly (my driver internally
   concatenates source strings, report always "0" and report concatenated
   string's line number.
   
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
// Compilation main function: compile vertex and fragment shaders, from
// common source combined with shader specific source.
//
//*****************************************************************************

GLuint gpuCompileProgram(string[] common, string[] vsfiles, string[] fsfiles)
{
    //-------------------------------------------------------------------------

    GLuint[] shaders = [
        compileShader(GL_VERTEX_SHADER,   common ~ vsfiles),
        compileShader(GL_FRAGMENT_SHADER, common ~ fsfiles)
    ];

    //-------------------------------------------------------------------------

    GLuint programID = checkgl!glCreateProgram();
    foreach(shaderID; shaders) checkgl!glAttachShader(programID, shaderID);
    checkgl!glLinkProgram(programID);

    if(!getProgram!bool(programID, GL_LINK_STATUS))
    {
        throw new ShaderCompileError
        (
            "Linking:\n" ~ getProgramInfoLog(programID)
        );
    }

    //-------------------------------------------------------------------------

    debug validate(programID);

    //debug dumpSymbols(programID);

    //-------------------------------------------------------------------------

    foreach(shaderID; shaders)
    {
        checkgl!glDetachShader(programID, shaderID);
        checkgl!glDeleteShader(shaderID);
    }

    return programID;
}

//*****************************************************************************
//
// Compiling shader
//
//*****************************************************************************

private GLuint compileShader(GLenum shadertype, string[] files)
{
    const string[GLenum] header = [
        GL_VERTEX_SHADER: "#define VERTEX_SHADER\n",
        GL_FRAGMENT_SHADER: "#define FRAGMENT_SHADER\n"
    ];

    //-------------------------------------------------------------------------
    // Construct string array from sources. At the top of the source we put
    // some built-ins. We allow null filenames for missing optional parts.
    //-------------------------------------------------------------------------

    const(char)* source[] = [
        toStringz("#version 120\n"),
        toStringz(header[shadertype])
    ];

    foreach(file; files) {
        if(file)
            source ~= toStringz(cast(string)blob.extract(file));
        else
            source ~= "";
    }

    files = [ "internal", "internal" ] ~ files;

    //-------------------------------------------------------------------------

    auto shaderID = checkgl!glCreateShader(shadertype);
    checkgl!glShaderSource(shaderID, cast(int)source.length, source.ptr, null);

    //-------------------------------------------------------------------------

    checkgl!glCompileShader(shaderID);

    if(getShader!bool(shaderID, GL_COMPILE_STATUS))
    {
        return shaderID;
    }

    //-------------------------------------------------------------------------

    //debug writeln(getShaderSource(shaderID));

    string msg = getShaderInfoLog(shaderID);
    auto errorat = new Location(msg);

    foreach(i, content; source)
    {
        ulong lines = countchars(to!string(content), "\n");
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
}

//*****************************************************************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// Getting source ID and line number from error message. TODO: Determine
// video driver, and write driver-specific regexes.
//-----------------------------------------------------------------------------

private class Location
{
    ulong fileid, line;
    string filename;
    string msg;

    this(string msg)
    {
        auto re = regex(
            r"^\s*(?P<fileid>\d+)\:(?P<line>\d+)\((?P<column>\d+)\)\:"
        );
        auto c = matchFirst(msg, re);

        this.fileid = to!ulong(c["fileid"]);
        this.line = to!ulong(c["line"]);
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
    int src_length;
    checkgl!glGetShaderiv(shaderID, GL_SHADER_SOURCE_LENGTH, &src_length);
    char[] buffer = new char[src_length];
    checkgl!glGetShaderSource(shaderID, src_length, null, buffer.ptr);
    return to!string(buffer);
}

private string getShaderInfoLog(GLuint shaderID)
{
    int log_length;
    checkgl!glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, &log_length);

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
    int log_length;
    checkgl!glGetProgramiv(programID, GL_INFO_LOG_LENGTH, &log_length);

    if(log_length)
    {
        char[] buffer = new char[log_length];
        glGetProgramInfoLog(programID, log_length, null, buffer.ptr);
        return to!string(buffer.ptr);
    }
    return "";
}

//-----------------------------------------------------------------------------
// Validation & symbol dumping
//-----------------------------------------------------------------------------

private void validate(GLuint programID)
{
    checkgl!glValidateProgram(programID);
    bool status = getProgram!bool(programID, GL_VALIDATE_STATUS);

    writeln("GLSL: Validate program ", programID, ": ", status ? "OK" : "Fail");

    if(!status) writeln("- Message: ", getProgramInfoLog(programID));
}

private void dumpSymbols(GLuint programID)
{
    int count = getProgram!int(programID, GL_ACTIVE_UNIFORMS);
    int maxlen = getProgram!int(programID, GL_ACTIVE_UNIFORM_MAX_LENGTH);
    char[] namebuf = new char[maxlen];

    string[GLenum] type2str = [
        GL_FLOAT: "float", GL_FLOAT_VEC2: "vec2", GL_FLOAT_VEC3: "vec3", GL_FLOAT_VEC4: "vec4",
        GL_INT: "int", GL_INT_VEC2: "ivec2", GL_INT_VEC3: "ivec3", GL_INT_VEC4: "ivec4",
        GL_BOOL: "bool", GL_BOOL_VEC2: "bvec2", GL_BOOL_VEC3: "bvec3", GL_BOOL_VEC4: "bvec4",
        GL_FLOAT_MAT2: "mat2", GL_FLOAT_MAT3: "mat3", GL_FLOAT_MAT4: "mat4",
        GL_SAMPLER_2D: "sampler2d",
        GL_SAMPLER_CUBE: "samplercube",
    ];

    writeln("Program: ", programID);

    writeln("- Uniforms:");

    foreach(uint i; 0 .. count)
    {
        GLint size;
        GLenum type;

        checkgl!glGetActiveUniform(
            programID, i, maxlen,
            null, 
            &size,
            &type,
            namebuf.ptr
        );

        writefln("    %2d: %-" ~ to!string(maxlen) ~"s: %d x %s",
            i,
            to!string(namebuf.ptr),
            size, type2str[type],
        );
    }

    writeln("- Vertex attributes: Not yet implemented.");
    writeln("- Varying: Not yet implemented.");

    //writeln("Uniforms: ", count);
    //writeln("Maxlen: ", maxlen);
}

