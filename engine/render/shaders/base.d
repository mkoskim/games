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
//-----------------------------------------------------------------------------
//
// TODO: There is definitely need for some sort of ShaderFamily instance.
// That is responsible for creating VBOs, IBOs and VAOs, suitable for use
// of the shaders in that family.
//
// Reasoning: Currently, we use shaders itself for uploading Models to
// GPU. As we don't know, which shaders can share the same VAOs, the
// models are currently tightly tied to shader code itself. This needs
// to be changed: you can (safely; supported by framework) change the shader
// rendering the model, as long as the shader belongs to the same family.
//
//*****************************************************************************

//-----------------------------------------------------------------------------

import engine.render.util;

import engine.render.shaders.gputypes;
import engine.render.shaders.gpumesh;
import engine.render.shaders.gpucompile: gpuCompileProgram;

import engine.render.transform;
import engine.render.mesh;
import engine.render.material;
import engine.render.bound;
import engine.render.texture;
import engine.render.view;
import engine.render.light;

import blob = engine.blob;
import std.string: toStringz;

//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------

abstract class Shader
{
    //*************************************************************************
    //
    // Methods that custom shaders need implement.
    //
    //*************************************************************************

    //abstract static Shader create();

    //-------------------------------------------------------------------------
    // Interfacing to shader uniforms
    //-------------------------------------------------------------------------
    
    abstract void loadView(View cam);
    abstract void loadMaterial(Material mat);

    //-------------------------------------------------------------------------
    // Rendering VAOs (Vertex Array Objects)
    //-------------------------------------------------------------------------
    
    abstract void render(Transform transform, VAO vao);
    abstract void render(Transform[] transforms, VAO vao);

    //-------------------------------------------------------------------------
    
    final void render(Transform transform, Material mat, VAO vao)
    {
        loadMaterial(mat);
        render(transform, vao);
    }

    final void render(Transform[] transforms, Material mat, VAO vao)
    {
        loadMaterial(mat);
        render(transforms, vao);
    }

    //*************************************************************************
    //
    // Methods that custom shaders can override
    //
    //*************************************************************************

    void light(Light l) { }

    //*************************************************************************
    //
    // Methods to implement shaders
    //
    //*************************************************************************

    //-------------------------------------------------------------------------
    // Getting locations of parameters
    //-------------------------------------------------------------------------

    private {
        GLint[string] _namecache;
        
        void _getlocation(string namespace, string name)
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
    //
    // VAO (Vertex Array Object) stores information of buffer binding.
    //
    //-------------------------------------------------------------------------

    protected {
        string[] attributes;
    }

    protected class VAO
    {
        //uint ID;

        BoundSphere bsp;
        VBO vbo;
        IBO ibo;

        this()  { /*checkgl!glGenVertexArrays(1, &ID);*/ }
        ~this() { /*checkgl!glDeleteVertexArrays(1, &ID);*/ }

        /*
        void bind() { checkgl!glBindVertexArray(ID); }
        void unbind() { checkgl!glBindVertexArray(0); }
        */

        void bind()
        {
            //foreach(vbo; vbos) vbo.connect();
            vbo.bind();
            foreach(name; attributes) {
                vbo.connect(location("attrib", name), name);
            }
            ibo.connect();
        }

        void unbind()
        {
            ibo.disconnect();
            foreach(name; attributes) {
                vbo.disconnect(location("attrib", name));
            }
            vbo.unbind();
        }
        
        //---------------------------------------------------------------------
        // Store bindings
        //---------------------------------------------------------------------

        void store() {
        /*
            bind();
            foreach(vbo; vbos) vbo.connect();
            ibo.connect();

            unbind();
            foreach(vbo; vbos) vbo.disconnect();
            ibo.disconnect();
        */
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

    //-------------------------------------------------------------------------
    //
    // Uploading mesh to GPU
    //
    //-------------------------------------------------------------------------

    private static void attrib(alias field)(VBO vbo, string name)
    {
        vbo.attrib!(typeof(field))(name, field.offsetof);
    }

    VAO upload(Mesh mesh)
    {
        auto vao = new VAO();

        if(mesh.mode == GL_TRIANGLES) mesh.computeTangents();

        vao.vbo = new VBO(
            mesh.vertices.ptr,
            mesh.vertices.length,
            mesh.VERTEX.sizeof
        );

        attrib!(mesh.VERTEX.pos)(vao.vbo, "vert_pos");
        attrib!(mesh.VERTEX.uv)(vao.vbo, "vert_uv");
        attrib!(mesh.VERTEX.normal)(vao.vbo, "vert_norm");
        attrib!(mesh.VERTEX.tangent)(vao.vbo, "vert_tangent");

        vao.bsp = BoundSphere.create(mesh);

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
            currentProgramID = programID;
        }
    }
}

