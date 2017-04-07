//*****************************************************************************
//
// Low level interface to shader
//
//*****************************************************************************

module engine.gpu.shader;

//-----------------------------------------------------------------------------

import engine.gpu.util;

import engine.gpu.types;
import engine.gpu.texture;
import engine.gpu.buffers;
import engine.gpu.compile;

import std.string: toStringz;
import std.variant: Variant;

//-----------------------------------------------------------------------------

class Shader
{
    //-------------------------------------------------------------------------
    // Options are values for uniforms. These might (should?) be moved to
    // OpenGL state object.
    //-------------------------------------------------------------------------
    
    Variant[string] options;

    //*************************************************************************
    //
    // Getting locations of shader parameters (uniforms and attributes). We
    // get these directly using Program ID, so we can bind buffers without
    // activating the shader itself.
    //
    //*************************************************************************

    struct PARAM {
        GLint  location;
        GLenum type;
        GLint  size;
    }

    PARAM[string] uniforms;
    PARAM[string] attributes;

    private auto getProgramParam(T)(GLenum name)
    {
        GLint result;
        checkgl!glGetProgramiv(programID, name, &result);
        return cast(T)result;
    }

    private void addUniform(GLint i) {
        int maxlen = getProgramParam!int(GL_ACTIVE_UNIFORM_MAX_LENGTH);
        char[] namebuf = new char[maxlen+1];
        
        GLint  size;
        GLenum type;
        checkgl!glGetActiveUniform(programID, i, maxlen, null, &size, &type, namebuf.ptr);
        GLint location = glGetUniformLocation(programID, namebuf.ptr);
        
        uniforms[to!string(namebuf.ptr)] = PARAM(location, type, size);
    }
        
    private void addAttribute(GLint i) {
        int maxlen = getProgramParam!int(GL_ACTIVE_ATTRIBUTE_MAX_LENGTH);
        char[] namebuf = new char[maxlen+1];

        GLenum type;
        GLint  size;
        checkgl!glGetActiveAttrib(programID, i, maxlen, null, &size, &type, namebuf.ptr);
        GLint location = glGetAttribLocation(programID, namebuf.ptr);
        
        attributes[to!string(namebuf.ptr)] = PARAM(location, type, size);
    }

    private void fillNameCache()
    {
        foreach(uint i; 0 .. getProgramParam!int(GL_ACTIVE_UNIFORMS))
        {
            addUniform(i);
        }

        foreach(uint i; 0 .. getProgramParam!int(GL_ACTIVE_ATTRIBUTES))
        {
            addAttribute(i);
        }
        
        dumpNameCache();
    }

    private void dumpNameCache()
    {
        writeln("- Uniforms:");
        foreach(name, param; uniforms) writefln("    %-20s@%d: %d x %s",
            name,
            param.location,
            param.size,
            glTypeName[param.type]
        );
        writeln("- Attributes:");
        foreach(name, param; attributes) writefln("    %-20s@%d: %d x %s",
            name,
            param.location,
            param.size,
            glTypeName[param.type]
        );
    }

    //*************************************************************************
    //
    // Shader uniforms
    //
    //*************************************************************************

    final void uniform(string name, Variant value)
    {
        GLint loc = uniforms[name].location;
        if(loc == -1) return ;

        if     (value.type == typeid(bool))   checkgl!glUniform1i(loc, value.get!(bool));
        else if(value.type == typeid(int))    checkgl!glUniform1i(loc, value.get!(int));
        else if(value.type == typeid(float))  checkgl!glUniform1f(loc, value.get!(float));
        else if(value.type == typeid(double)) checkgl!glUniform1f(loc, cast(float)value.get!(double));
        else if(value.type == typeid(mat4))   checkgl!glUniformMatrix4fv(loc, 1, GL_TRUE, value.get!(mat4).value_ptr);
        else if(value.type == typeid(vec4))   checkgl!glUniform4fv(loc, 1, value.get!(vec4).value_ptr);
        else if(value.type == typeid(vec3))   checkgl!glUniform3fv(loc, 1, value.get!(vec3).value_ptr);
        else throw new Exception(format("Unknown type '%s' for uniform '%s'", to!string(value.type), name));
    }

    final void uniform(string n, mat4 v)  { uniform(n, Variant(v)); }
    final void uniform(string n, vec4 v)  { uniform(n, Variant(v)); }
    final void uniform(string n, vec3 v)  { uniform(n, Variant(v)); }
    final void uniform(string n, float v) { uniform(n, Variant(v)); }
    final void uniform(string n, int v)   { uniform(n, Variant(v)); }
    final void uniform(string n, bool v)  { uniform(n, Variant(v)); }

    //*************************************************************************
    //
    // Texture samplers
    //
    //*************************************************************************

    final void uniform(string name, Texture texture, GLenum unit)
    {
        GLint loc = uniforms[name].location;
        if(loc != -1) {
            checkgl!glActiveTexture(GL_TEXTURE0 + unit);
            checkgl!glBindTexture(GL_TEXTURE_2D, texture.ID);
            checkgl!glUniform1i(loc, unit);
        }
    }

    final void uniform(string name, Cubemap cubemap, GLenum unit)
    {
        GLint loc = uniforms[name].location;
        if(loc != -1) {
            checkgl!glActiveTexture(GL_TEXTURE0 + unit);
            checkgl!glBindTexture(GL_TEXTURE_CUBE_MAP, cubemap.ID);
            checkgl!glUniform1i(loc, unit);
        }
    }

    //*************************************************************************
    //
    // Connecting attributes from buffers. In fact, it would be easier to use
    // non-interleaved buffers. Although interleaved ones are nice and compact,
    // they cause lots of extra hassling. In addition, with interleaved ones
    // it is harder to add vertex data to shaders.
    //
    //*************************************************************************
    
    private void connect(VBO vbo, string name, GLenum type, GLint elems, bool normalized, size_t offset, size_t rowsize)
    {
        GLint loc = attributes[name].location;
        if(loc == -1) return;

        vbo.bind();
        checkgl!glVertexAttribPointer(
            loc,                        // attribute location
            elems,                      // size
            type,                       // type
            normalized,                 // normalized?
            cast(GLint)rowsize,         // stride
            cast(void*)offset           // array buffer offset
        );
        vbo.unbind();
        checkgl!glEnableVertexAttribArray(loc);
    }

    private void disconnect(string name)
    {
        GLint loc = attributes[name].location;
        checkgl!glDisableVertexAttribArray(loc);
    }

    //-------------------------------------------------------------------------

    void attrib(string name, GLenum type, VBO vbo)
    {
        switch(type) {
            case GL_FLOAT     : connect(vbo, name, GL_FLOAT, 1, false, 0, 0); break;
            case GL_FLOAT_VEC2: connect(vbo, name, GL_FLOAT, 2, false, 0, 0); break;
            case GL_FLOAT_VEC3: connect(vbo, name, GL_FLOAT, 3, false, 0, 0); break;
            case GL_FLOAT_VEC4: connect(vbo, name, GL_FLOAT, 4, false, 0, 0); break;
            default: throw new Exception(format("Unknown type '%s' for attribute '%s'", to!string(type), name));
        }            
    }

/*
    void attrib(T: vec2)(string name, size_t offset, size_t rowsize) { connect(name, GL_FLOAT, 2, false, offset, rowsize); }
    void attrib(T: vec3)(string name, size_t offset, size_t rowsize) { connect(name, GL_FLOAT, 3, false, offset, rowsize); }
    void attrib(T: vec4)(string name, size_t offset, size_t rowsize) { connect(name, GL_FLOAT, 4, false, offset, rowsize); }

    void attrib(T: ivec4x8b)(string name, size_t offset, size_t rowsize) { connect(name, T.gltype, T.glsize, T.glnormd, offset, rowsize); }
    void attrib(T: fvec2x16b)(string name, size_t offset, size_t rowsize) { connect(name, T.gltype, T.glsize, T.glnormd, offset, rowsize); }

    //void attrib(T: ivec3x10b)(string name, size_t offset) { setattrib(name, T.gltype, T.glsize, T.glnormd, offset); }

    void attrib(T)(string name, size_t offset, size_t rowsize) { throw new Error("Attribute type " ~ T.stringof ~ " not implemented."); }

    static void attrib(alias field)(Shader shader, string name, size_t rowsize)
    {
        shader.attrib!(typeof(field))(name, field.offsetof, rowsize);
    }
*/

    //*************************************************************************
    //
    // Shader activation
    //
    //*************************************************************************

    void setOptions(Variant[string] options)
    {
        foreach(name, value; options) uniform(name, value);
    }

    final void activate()
    {
        static currentProgramID = 0;

        if(currentProgramID != programID)
        {
            checkgl!glUseProgram(programID);
            setOptions(options);
            currentProgramID = programID;
        }
    }

    //*************************************************************************
    //
    // Constructors, GLSL compiling
    //
    //*************************************************************************

    GLuint programID;

    this(GLuint ID) {
        debug Track.add(this);
        programID = ID;
        fillNameCache();
    }

    //-------------------------------------------------------------------------

    this(string vs_source, string fs_source)
    {
        this(CompileProgram(vs_source, fs_source));
    }

    this(string source)
    {
        this(source, source);
    }

    //-------------------------------------------------------------------------

    ~this() {
        debug Track.remove(this);
        if(programID) glDeleteProgram(programID);
    }
}

