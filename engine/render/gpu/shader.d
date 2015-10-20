//*****************************************************************************
//
// Low level interface to shader
//
//*****************************************************************************

module engine.render.gpu.shader;

//-----------------------------------------------------------------------------

import engine.render.util;

import engine.render.gpu.types;
import engine.render.gpu.texture;
import engine.render.gpu.buffers;
import engine.render.gpu.compile;

//import engine.render.types.bounds;
//import engine.render.types.mesh;

import std.string: toStringz;
import std.variant: Variant;

//-----------------------------------------------------------------------------

class Shader
{
    //*************************************************************************
    //
    // Getting locations of shader parameters (uniforms and attributes)
    //
    //*************************************************************************

    private {
        GLint[string] _namecache;

        void _getlocation(string namespace, string name, bool optional)
        {
            extern(C) GLint function(GLuint, const(char)*) query;

            switch(namespace)
            {
                case "uniform": query = glGetUniformLocation; break;
                case "attrib":  query = glGetAttribLocation; break;
                default: throw new Exception("Invalid namespace: " ~ namespace);
            }

            GLint loc = checkgl!query(programID, name.toStringz);
            if(loc == -1 && !optional) throw new Exception("Unknown GLSL identifier: " ~ name);
            _namecache[name] = loc;
        }
    }

    protected final GLint location(string namespace, string name, bool optional)
    {
        if(!(name in _namecache)) _getlocation(namespace, name, optional);
        //debug writeln("Location: ", name, " @ ", locations[name]);
        return _namecache[name];
    }

    debug void dumpNameCache()
    {
        foreach(id; _namecache.keys)
        {
            writeln(id, " @ ", _namecache[id]);
        }
    }

    //*************************************************************************
    //
    // Shader uniforms and options
    //
    //*************************************************************************

    final void uniform(string name, Variant value, bool optional = false)
    {
        GLint loc = location("uniform", name, optional);
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

    final void uniform(string n, mat4 v, bool opt = false) { uniform(n, Variant(v), opt); }
    final void uniform(string n, vec4 v, bool opt = false) { uniform(n, Variant(v), opt); }
    final void uniform(string n, vec3 v, bool opt = false) { uniform(n, Variant(v), opt); }
    final void uniform(string n, float v, bool opt = false) { uniform(n, Variant(v), opt); }
    final void uniform(string n, int v, bool opt) { uniform(n, Variant(v), opt); }
    final void uniform(string n, bool v, bool opt) { uniform(n, Variant(v), opt); }

    Variant[string] options;

    //-------------------------------------------------------------------------
    // Texture sampler. TODO: Maybe we change this to uniform.
    //-------------------------------------------------------------------------

    final void texture(string name, GLenum unit, Texture texture, bool optional = false)
    {
        GLint loc = location("uniform", name, optional);
        if(loc != -1) {
            checkgl!glActiveTexture(GL_TEXTURE0 + unit);
            checkgl!glBindTexture(GL_TEXTURE_2D, texture.ID);
            checkgl!glUniform1i(loc, unit);
        }
    }

    final void texture(string name, GLenum unit, Cubemap cubemap, bool optional = false)
    {
        GLint loc = location("uniform", name, optional);
        if(loc != -1) {
            checkgl!glActiveTexture(GL_TEXTURE0 + unit);
            checkgl!glBindTexture(GL_TEXTURE_CUBE_MAP, cubemap.ID);
            checkgl!glUniform1i(loc, unit);
        }
    }

    //*************************************************************************
    //
    // Binding VBO fields to attributes
    //
    //*************************************************************************

    /*
    struct ATTRIB
    {
        GLenum type;        // GL_FLOAT, ...
        GLint elems;        // Number of elements in this attribute (1 .. 4)
        GLboolean normd;    // Normalized / not
        size_t offset;       // Offset in interleaved buffers
    }

    ATTRIB[string] attribs;

    void setattrib(string name, GLenum type, GLint elems, bool normalized, size_t offset) {
        attribs[name] = ATTRIB(
            //location("attrib", name),
            type,
            elems,
            normalized ? GL_TRUE : GL_FALSE,
            offset
        );
    }
    */

    //-------------------------------------------------------------------------

    /*
    string[] attributes;

    bool hasAttribute(string key)
    {
        foreach(attr; attributes) if(key == attr) return true;
        return false;
    }
    */

    void connect(string name, GLenum type, GLint elems, bool normalized, size_t offset, size_t rowsize)
    {
        GLint loc = location("attrib", name, true);
        if(loc == -1) return;

        checkgl!glVertexAttribPointer(
            loc,                        // attribute location
            elems,                      // size
            type,                       // type
            normalized,                 // normalized?
            cast(GLint)rowsize,         // stride
            cast(void*)offset           // array buffer offset
        );
        checkgl!glEnableVertexAttribArray(loc);
    }

    void disconnect(string name)
    {
        GLint loc = location("attrib", name, true);
        checkgl!glDisableVertexAttribArray(loc);
    }

    //-------------------------------------------------------------------------

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

    //*************************************************************************
    //
    // Shader activation
    //
    //*************************************************************************

    void setOptions(Variant[string] options)
    {
        foreach(name, value; options) uniform(name, value);
    }

    private static currentProgramID = 0;

    final void activate()
    {
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

    this() { programID = 0; }

    //-------------------------------------------------------------------------

    this(string[] common, string[] vsfiles, string[] fsfiles)
    {
        programID = CompileProgram(common, vsfiles, fsfiles);
    }

    this(string filename) { this([], [filename], [filename]); }
    this(string vsfile, string fsfile) { this([], [vsfile], [fsfile]); }

    //-------------------------------------------------------------------------

    ~this() {
        if(programID) glDeleteProgram(programID);
    }
}

