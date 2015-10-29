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

    bool[string] features;  // Features of this shader for upper levels
    bool[string] optional;  // Try to look for uniform, but don't care if it does not exist
    bool[string] rejected;  // Don't even try to look uniform
    
    void setFeatures(string[] names...) {
        foreach(name; names) features[name] = true;
    }
    
    void setOptional(string[] names...) {
        foreach(name; names) optional[name] = true;
    }
    
    void setRejected(string[] names...) {
        foreach(name; names) rejected[name] = true;
    }
    
    private {
        GLint[string] _namecache;

        void _getlocation(string namespace, string name)
        {
            if(name in rejected) {
                _namecache[name] = -1;
                return;
            }

            extern(C) GLint function(GLuint, const(char)*) query;

            switch(namespace)
            {
                case "uniform": query = glGetUniformLocation; break;
                case "attrib":  query = glGetAttribLocation; break;
                default: throw new Exception("Invalid namespace: " ~ namespace);
            }

            GLint loc = checkgl!query(programID, name.toStringz);
            if(loc == -1 && !(name in optional)) throw new Exception("Unknown GLSL identifier: " ~ name);
            _namecache[name] = loc;
        }
    }

    protected final GLint location(string namespace, string name)
    {
        if(!(name in _namecache)) _getlocation(namespace, name);
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

    final void uniform(string name, Variant value)
    {
        GLint loc = location("uniform", name);
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

    Variant[string] options;

    //-------------------------------------------------------------------------
    // Texture sampler. TODO: Maybe we change this to uniform.
    //-------------------------------------------------------------------------

    final void texture(string name, GLenum unit, Texture texture)
    {
        GLint loc = location("uniform", name);
        if(loc != -1) {
            checkgl!glActiveTexture(GL_TEXTURE0 + unit);
            checkgl!glBindTexture(GL_TEXTURE_2D, texture.ID);
            checkgl!glUniform1i(loc, unit);
        }
    }

    final void texture(string name, GLenum unit, Cubemap cubemap)
    {
        GLint loc = location("uniform", name);
        if(loc != -1) {
            checkgl!glActiveTexture(GL_TEXTURE0 + unit);
            checkgl!glBindTexture(GL_TEXTURE_CUBE_MAP, cubemap.ID);
            checkgl!glUniform1i(loc, unit);
        }
    }

    //-------------------------------------------------------------------------

    void connect(string name, GLenum type, GLint elems, bool normalized, size_t offset, size_t rowsize)
    {
        GLint loc = location("attrib", name);
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
        GLint loc = location("attrib", name);
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

    this(GLuint ID = 0) {
        debug Track.add(this);
        programID = ID;
    }

    //-------------------------------------------------------------------------

    this(string[] common, string[] vsfiles, string[] fsfiles)
    {
        debug Track.add(this);
        programID = CompileProgram(common, vsfiles, fsfiles);
    }

    this(string filename) { this([], [filename], [filename]); }
    this(string vsfile, string fsfile) { this([], [vsfile], [fsfile]); }

    //-------------------------------------------------------------------------

    ~this() {
        debug Track.remove(this);
        if(programID) glDeleteProgram(programID);
    }
}

