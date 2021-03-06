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
import core.exception;

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

    //-------------------------------------------------------------------------

    PARAM[string] uniforms;

    private void addUniform(string name, PARAM param)
    {
        uniforms[name] = param;
    }

    private void addUniform(string name, GLint location, GLenum type, GLint size)
    {
        addUniform(name, PARAM(location, type, size));
    }

    GLint uniformLocation(string name)
    {
        try {
            return uniforms[name].location;
        } catch(core.exception.RangeError) {
            return -1;
        }
    }

    //-------------------------------------------------------------------------
    // Shaders are organized to families. In all simplicity, shader family
    // ensures that attributes with same name get the same index number. Thus,
    // when vertex buffers are bind to certain indices to feed the attributes, 
    // all shaders in the same family receives them to attributes with same
    // name --> you can bind attributes by shader family, and all shaders in
    // that family can use the same bindings. Diagram:
    //
    // Binding      Family      Shader A    Shader B    Index
    // vert_pos     vert_pos    vert_pos    vert_pos    1
    // vert_TBN     vert_TBN    vert_TBN    -           2
    // -            vert_extra  -           -           3
    //
    //-------------------------------------------------------------------------
    
    static class Family
    {
        PARAM[string] attributes;

        void addAttribute(string name, PARAM param)
        {
            attributes[name] = param;
        }

        void addAttribute(string name, GLint location, GLenum type, GLint size)
        {
            addAttribute(name, PARAM(location, type, size));
        }

        GLint attribLocation(string name)
        {
            try {
                return attributes[name].location;
            } catch(core.exception.RangeError) {
                return -1;
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
            GLint loc = attribLocation(name);
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
            GLint loc = attribLocation(name);
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
    
        void dumpNameCache()
        {
            Log << "Family Bindings:";
            foreach(name, param; attributes) Log << format("    %-20s@%d: %d x %s",
                name,
                param.location,
                param.size,
                GLenumName[param.type]
            );
        }
    }
    
    Family family;
    
    //-------------------------------------------------------------------------

    private void dump(string name, PARAM param)
    {
    /*
        writefln("    %-20s@%d: %d x %s",
            name,
            param.location,
            param.size,
            GLenumName[param.type]
        );
        */
    }

    //-------------------------------------------------------------------------

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
        
        addUniform(to!string(namebuf.ptr), location, type, size);
    }
        
    private void addAttribute(GLint i) {
        int maxlen = getProgramParam!int(GL_ACTIVE_ATTRIBUTE_MAX_LENGTH);
        char[] namebuf = new char[maxlen+1];

        GLenum type;
        GLint  size;
        checkgl!glGetActiveAttrib(programID, i, maxlen, null, &size, &type, namebuf.ptr);
        GLint location = glGetAttribLocation(programID, namebuf.ptr);
        
        auto name  = to!string(namebuf.ptr);
        auto param = PARAM(location, type, size);

        dump(name, param);
        family.addAttribute(name, param);
    }

    private void updateNameCache()
    {
        //writeln("- Active uniforms:");
        
        foreach(uint i; 0 .. getProgramParam!int(GL_ACTIVE_UNIFORMS))
        {
            addUniform(i);
        }

        //writeln("- Active attributes:");
        
        foreach(uint i; 0 .. getProgramParam!int(GL_ACTIVE_ATTRIBUTES))
        {
            addAttribute(i);
        }
        
        //dumpNameCache();
    }

    //*************************************************************************
    //
    // Shader uniforms
    //
    //*************************************************************************

    final void uniform(string name, Variant value)
    {
        GLint loc = uniformLocation(name);
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
        GLint loc = uniformLocation(name);
        
        if(loc != -1) {
            checkgl!glActiveTexture(GL_TEXTURE0 + unit);
            checkgl!glBindTexture(GL_TEXTURE_2D, texture.ID);
            checkgl!glUniform1i(loc, unit);
        }
    }

    final void uniform(string name, Cubemap cubemap, GLenum unit)
    {
        GLint loc = uniformLocation(name);

        if(loc != -1) {
            checkgl!glActiveTexture(GL_TEXTURE0 + unit);
            checkgl!glBindTexture(GL_TEXTURE_CUBE_MAP, cubemap.ID);
            checkgl!glUniform1i(loc, unit);
        }
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
            currentProgramID = programID;
            setOptions(options);
        }
    }

    //*************************************************************************
    //
    // Constructors, GLSL compiling
    //
    //*************************************************************************

    GLuint   programID;
    
    private this(Family family, GLuint ID)
    {
        debug Track.add(this);
        programID = ID;
        this.family = family;
        updateNameCache();
    }

    ~this() {
        debug Track.remove(this);
        if(programID) glDeleteProgram(programID);
    }

    //-------------------------------------------------------------------------

    this(Family family, string vs_src, string gs_src, string fs_src)
    {
        this(family, CompileProgram(family, vs_src, gs_src, fs_src));
    }
    
    this(Family family, string vs_src, string fs_src)
    { 
        this(family, vs_src, null, fs_src);
    }
    
    this(string vs_src, string fs_src)
    {
        this(new Family(), vs_src, fs_src);
    }

    this(Family family, string source) { this(family, source, source); }
    this(string source)                { this(new Family(), source); }
}
