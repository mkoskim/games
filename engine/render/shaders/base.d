//*****************************************************************************
//
// Shaders base class, inspired by glamour
//
//*****************************************************************************

module engine.render.shaders.base;

//*****************************************************************************
//
// Current plan is to move shader a lower level component. We implement
// primitives to set up rendering, and functions to render different
// primitive data types.
//
//*****************************************************************************

//-----------------------------------------------------------------------------

import engine.render.util;
import engine.render.shaders.gputypes;
import engine.render.shaders.gpucompile: gpuCompileProgram;

import engine.render.bone;
import engine.render.mesh;
import engine.render.material;
import engine.render.bound;
import engine.render.texture;
import engine.render.view;
import engine.render.light;

import blob = engine.blob;
import std.string: toStringz;

//-----------------------------------------------------------------------------

abstract class Shader
{
    /* TODO: Implement mechanism for shader options */

    bool fill = true;       // Fill / wireframe
    bool enabled = true;    // Render on/off

    //*************************************************************************
    //
    // Methods that custom shaders need implement.
    //
    //*************************************************************************

    //abstract static Shader create();

    abstract protected void addVBOs(VAO vao, Mesh mesh);

    //-------------------------------------------------------------------------
    
    abstract void loadView(View cam);
    abstract void loadMaterial(Material mat);

    abstract void render(Bone grip, VAO vao);
    abstract void render(Bone[] grips, VAO vao);

    //-------------------------------------------------------------------------
    
    final void render(Bone grip, Material mat, VAO vao)
    {
        loadMaterial(mat);
        render(grip, vao);
    }

    final void render(Bone[] grips, Material mat, VAO vao)
    {
        loadMaterial(mat);
        render(grips, vao);
    }

    //*************************************************************************
    //
    // Methods that custom shaders can override
    //
    //*************************************************************************

    void light(Light l) { }

    protected void apply()
    {
        glPolygonMode(GL_FRONT, fill ? GL_FILL : GL_LINE);
    }

    //*************************************************************************
    //
    // Methods to implement shaders
    //
    //*************************************************************************

    //-------------------------------------------------------------------------
    // Getting locations of parameters
    //-------------------------------------------------------------------------

    private GLint[string] _namecache;

    protected final GLint location(string namespace, string name)
    {
        if(!(name in _namecache))
        {
            extern(C) GLint function(GLuint, const(char)*) query;

            switch(namespace)
            {
                case "uniform": query = glGetUniformLocation; break;
                case "attrib":  query = glGetAttribLocation; break;
                default: throw new Exception("Invalid namespace: " ~ namespace);
            }

            GLint loc = checkgl!query(programID, name.toStringz);
            if(loc == -1) throw new Exception("Unknown GLSL identifier: " ~ name);
            _namecache[name] = loc;
        }
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

    //-------------------------------------------------------------------------
    // Uniform parameters
    //-------------------------------------------------------------------------

    protected final void uniform(string name, mat4 value)
    {
        checkgl!glUniformMatrix4fv(location("uniform", name), 1, GL_TRUE, value.value_ptr);
    }

    protected final void uniform(string name, vec4 value)
    {
        checkgl!glUniform4fv(location("uniform", name), 1, value.value_ptr);
    }

    protected final void uniform(string name, vec3 value)
    {
        checkgl!glUniform3fv(location("uniform", name), 1, value.value_ptr);
    }

    protected final void uniform(string name, float value)
    {
        checkgl!glUniform1f(location("uniform", name), value);
    }

    protected final void uniform(string name, bool value)
    {
        checkgl!glUniform1ui(location("uniform", name), value);
    }

    //-------------------------------------------------------------------------
    // Texture sampler. TODO: Maybe we change this to uniform.
    //-------------------------------------------------------------------------

    protected final void texture(string name, GLenum unit, Texture texture)
    {
        checkgl!glActiveTexture(GL_TEXTURE0 + unit);
        checkgl!glBindTexture(GL_TEXTURE_2D, texture.ID);
        checkgl!glUniform1i(location("uniform", name), unit);
    }

    //-------------------------------------------------------------------------
    // Vertex data buffers (VBO, Vertex Buffer Object)
    //-------------------------------------------------------------------------

    static void attrib(alias field)(VBO vbo, string name)
    {
        vbo.attrib!(typeof(field))(name, field.offsetof);
    }

    protected class VBO
    {
        GLuint ID;      // VBO ID
        ulong rowsize; // Data row size

        this(void* buffer, size_t length, size_t elemsize, uint mode = GL_STATIC_DRAW)
        {
            checkgl!glGenBuffers(1, &ID);
            checkgl!glBindBuffer(GL_ARRAY_BUFFER, ID);
            checkgl!glBufferData(GL_ARRAY_BUFFER, length * elemsize, buffer, mode);
            checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0);

            rowsize = elemsize;
        }

        ~this()
        {
            checkgl!glDeleteBuffers(1, &ID);
            //writeln("~VBO.this: ", ID);
        }

        //---------------------------------------------------------------------

        void bind()   { checkgl!glBindBuffer(GL_ARRAY_BUFFER, ID); }
        void unbind() { checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0); }

        //---------------------------------------------------------------------

        void connect() {
            bind();
            foreach(attr; attribs) connect(attr);
        }

        void disconnect() {
            foreach(attr; attribs) disconnect(attr);
            unbind();
        }

        //---------------------------------------------------------------------

        private {
            struct ATTRIB
            {
                GLuint loc;         // Shader attribute location
                GLenum type;        // GL_FLOAT, ...
                GLint elems;        // Number of elements in this attribute (1 .. 4)
                GLboolean normd;    // Normalized / not
                ulong offset;       // Offset in interleaved buffers
            }

            ATTRIB[] attribs;

            void setattrib(string name, GLenum type, GLint elems, bool normalized, ulong offset) {
                attribs ~= ATTRIB(
                    location("attrib", name),
                    type,
                    elems,
                    normalized ? GL_TRUE : GL_FALSE,
                    offset
                );
            }

            void attrib(T: vec2)(string name, ulong offset) { setattrib(name, GL_FLOAT, 2, false, offset); }
            void attrib(T: vec3)(string name, ulong offset) { setattrib(name, GL_FLOAT, 3, false, offset); }
            void attrib(T: vec4)(string name, ulong offset) { setattrib(name, GL_FLOAT, 4, false, offset); }

            void attrib(T: ivec4x8b)(string name, ulong offset) { setattrib(name, T.gltype, T.glsize, T.glnormd, offset); }
            void attrib(T: ivec3x10b)(string name, ulong offset) { setattrib(name, T.gltype, T.glsize, T.glnormd, offset); }
            void attrib(T: fvec2x16b)(string name, ulong offset) { setattrib(name, T.gltype, T.glsize, T.glnormd, offset); }

            void attrib(T)(string name, ulong offset) { throw new Error("Attribute type " ~ T.stringof ~ " not implemented."); }

            //-----------------------------------------------------------------

            void connect(ATTRIB attr)
            {
                checkgl!glVertexAttribPointer(
                    attr.loc,                   // attribute location
                    attr.elems,                 // size
                    attr.type,                  // type
                    attr.normd,                 // normalized?
                    cast(int)rowsize,           // stride
                    cast(void*)attr.offset      // array buffer offset
                );
                checkgl!glEnableVertexAttribArray(attr.loc);
            }

            void disconnect(ATTRIB attr)
            {
                checkgl!glDisableVertexAttribArray(attr.loc);
            }
        }
    }

    //-------------------------------------------------------------------------

    protected class IBO
    {
        uint ID;
        uint length;
        uint drawmode;

        this(uint drawmode, ushort[] faces, uint mode = GL_STATIC_DRAW)
        {
            length = cast(uint)faces.length;
            this.drawmode = drawmode;

            checkgl!glGenBuffers(1, &ID);
            checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ID);
            checkgl!glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                faces.length * ushort.sizeof,
                faces.ptr, mode
            );
            checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        }

        ~this()
        {
            checkgl!glDeleteBuffers(1, &ID);
        }

        void connect() { checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ID); }
        void disconnect() { checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); }

        void draw() {
            checkgl!glDrawElements(drawmode, length, GL_UNSIGNED_SHORT, null);
        }
    }

    //-------------------------------------------------------------------------
    //
    // VAO (Vertex Array Object) stores information of buffer binding.
    //
    //-------------------------------------------------------------------------

    protected class VAO
    {
        uint ID;

        BoundSphere bsp;
        VBO[] vbos;
        IBO   ibo;

        this()  { checkgl!glGenVertexArrays(1, &ID); }
        ~this() { checkgl!glDeleteVertexArrays(1, &ID); }

        void bind() { checkgl!glBindVertexArray(ID); }
        void unbind() { checkgl!glBindVertexArray(0); }

        //---------------------------------------------------------------------
        // Store bindings
        //---------------------------------------------------------------------

        void store() {
            bind();
            foreach(vbo; vbos) vbo.connect();
            ibo.connect();

            unbind();
            foreach(vbo; vbos) vbo.disconnect();
            ibo.disconnect();
        }

        //---------------------------------------------------------------------
        // The plan to draw multi-material meshes is that we "merge" face
        // lists to 1 IBO, and use start and end indices to draw it in
        // multiple phases (binding new materials between).
        //---------------------------------------------------------------------

        /*
        void draw()
        {
            bind();
            ibo.draw();
            unbind();
        }
        */
    }

    VAO upload(Mesh mesh)
    {
        auto vao = new VAO();

        if(mesh.mode == GL_TRIANGLES) mesh.computeTangents();
        vao.bsp = BoundSphere.create(mesh);
        addVBOs(vao, mesh);
        vao.ibo = new IBO(mesh.mode, mesh.faces);

        vao.store();

        return vao;
    }

    //*************************************************************************
    //
    // Constructors, GLSL compiling
    //
    //*************************************************************************

    GLuint programID;

    protected this() { programID = 0; }

    //-------------------------------------------------------------------------

    protected this(string[] common, string[] vsfiles, string[] fsfiles)
    {
        programID = gpuCompileProgram(common, vsfiles, fsfiles);
    }

    protected this(string filename) { this([], [filename], [filename]); }
    protected this(string vsfile, string fsfile) { this([], [vsfile], [fsfile]); }

    //-------------------------------------------------------------------------

    ~this() {
        if(programID) glDeleteProgram(programID);
    }

    //-------------------------------------------------------------------------

    final void activate()
    {
        static currentProgramID = 0;

        if(currentProgramID != programID)
        {
            checkgl!glUseProgram(programID);
            apply();
            currentProgramID = programID;
        }
    }
}

