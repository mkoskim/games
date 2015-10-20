//*****************************************************************************
//
// Shader(s) for 3D pipeline
//
//*****************************************************************************

module engine.render.scene3d.shader;

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------

import engine.render.util;

import gpu = engine.render.gpu;
import engine.render.loader.mesh;

import engine.render.scene3d.types.transform;
import engine.render.scene3d.types.material;
import engine.render.scene3d.types.bounds;
import engine.render.scene3d.types.view;
import engine.render.scene3d.types.light;

//import blob = engine.blob;
//import std.string: toStringz;

//-----------------------------------------------------------------------------
// TODO: Shader needs to be renamed
//-----------------------------------------------------------------------------

abstract class Shader : gpu.Shader
{
    //*************************************************************************
    //
    // Methods that custom shaders need implement.
    //
    //*************************************************************************

    //abstract static Shader create();

    //-------------------------------------------------------------------------

    //*************************************************************************
    //
    // Camera
    //
    //*************************************************************************

    void loadView(View cam)
    {
        uniform("mProjection", cam.mProjection());
        uniform("mView", cam.mView());
    }

    //*************************************************************************
    //
    // Lights
    //
    //*************************************************************************

    void light(Light l)
    {
        uniform("light.pos", l.transform.worldspace());

        uniform("light.radius", l.radius);
        uniform("light.ambient", l.ambient);
        uniform("light.color", l.color);
    }

    //*************************************************************************
    //
    // Rendering
    //
    //*************************************************************************

    void loadMaterial(Material mat, Material.Modifier mod)
    {
        texture("material.colormap", 0, mat.colormap);
        texture("material.normalmap", 1, mat.normalmap);

        uniform("material.roughness", mat.roughness);

        if(mod is null) {
            uniform("material.modifier.color", vec4(1, 1, 1, 1));
        }
        else {
            uniform("material.modifier.color", mod.color);
        }
    }

    final void render(Transform transform, Material mat, VAO vao)
    {
        loadMaterial(mat, null);
        render(transform, vao);
    }

    final void render(Transform[] transforms, Material mat, VAO vao)
    {
        loadMaterial(mat, null);
        render(transforms, vao);
    }

    //-------------------------------------------------------------------------

    void render(mat4 transform, VAO vao)
    {
        uniform("mModel", transform);

        vao.vao.bind();
        vao.ibo.draw();
        vao.vao.unbind();
    }

    void render(Transform[] transforms, VAO vao)
    {
        vao.vao.bind();
        foreach(transform; transforms)
        {
            uniform("mModel", transform.mModel());
            vao.ibo.draw();
        }
        vao.vao.unbind();
    }

    void render(Transform transform, VAO vao)
    {
        render(transform.mModel(), vao);
    }

    //*************************************************************************
    //
    // Can we use uniform buffers for materials?
    //
    //*************************************************************************

    //*************************************************************************
    //
    // Uploading mesh to GPU
    //
    //*************************************************************************

    protected class VAO
    {
        BoundSphere bsp;

        gpu.VBO vbo;
        gpu.IBO ibo;
        gpu.VAO vao;
    }

    struct VERTEX
    {
        vec3 pos;
        gpu.fvec2x16b uv;
        gpu.ivec4x8b normal;
        gpu.ivec4x8b tangent;

        ubyte[8] padding;

        //---------------------------------------------------------------------

        static assert(VERTEX.sizeof == 32);

        //---------------------------------------------------------------------

        this(vec3 pos, vec2 uv, vec3 norm, vec4 tangent)
        {
            this.pos = pos;
            this.uv = uv;
            this.normal = vec4(norm, 0).normalized();
            this.tangent = tangent.normalized(); //vec4(0, 0, 0, 0);
        }
    }

    //-------------------------------------------------------------------------
    
    VAO upload(Mesh mesh)
    {
        if(mesh.mode == GL_TRIANGLES) mesh.computeTangents();

        VERTEX[] vertbuf = new VERTEX[mesh.vertices.length];

        foreach(i; 0 .. vertbuf.length)
        {
            vertbuf[i] = VERTEX(
                mesh.vertices[i].pos,
                mesh.vertices[i].uv,
                mesh.vertices[i].normal,
                mesh.vertices[i].tangent
            );
        }

        auto vao = new VAO();

        vao.vao = new gpu.VAO();
        vao.vao.bind();

        vao.vbo = new gpu.VBO(
            vertbuf.ptr,
            vertbuf.length,
            VERTEX.sizeof
        );
        vao.vbo.bind();

        attrib!(VERTEX.pos)(this, "vert_pos", VERTEX.sizeof);
        attrib!(VERTEX.uv)(this, "vert_uv", VERTEX.sizeof);
        attrib!(VERTEX.normal)(this, "vert_norm", VERTEX.sizeof);
        attrib!(VERTEX.tangent)(this, "vert_tangent", VERTEX.sizeof);

        vao.bsp = BoundSphere.create(mesh);

        vao.ibo = new gpu.IBO(mesh.mode, mesh.faces);
        vao.ibo.bind();

        vao.vao.unbind();
        vao.vbo.unbind();
        vao.ibo.unbind();

        return vao;
    }

    //-------------------------------------------------------------------------

    protected this(string[] common, string[] vsfiles, string[] fsfiles)
    {
        super(common, vsfiles, fsfiles);
    }

    protected this(string filename) { this([], [filename], [filename]); }
    protected this(string vsfile, string fsfile) { this([], [vsfile], [fsfile]); }
}

//*****************************************************************************
//
// Some 3D shaders
//
//*****************************************************************************

class Default3D : Shader
{
    static Shader create()
    {
        static Shader instance = null;
        if(!instance) instance = new Default3D();
        return instance;
    }

    //-------------------------------------------------------------------------

    protected this(string conffile)
    {
        super(
            [
                conffile,
                "engine/render/scene3d/glsl/types.3d.glsl",
                "engine/render/scene3d/glsl/default3d.in.glsl",
            ], [
                "engine/render/scene3d/glsl/verts.lib.glsl",
                "engine/render/scene3d/glsl/verts.3d.glsl",
            ], [
                "engine/render/scene3d/glsl/frags.lib.glsl",
                "engine/render/scene3d/glsl/frags.3d.glsl",
            ]
        );
    }

    private this()
    {
        this(null);
    }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

class Flat3D : Shader
{
    static Shader create()
    {
        static Shader instance = null;
        if(!instance) instance = new Flat3D();
        return instance;
    }

    //-------------------------------------------------------------------------

    override void light(Light l) { }
    override void loadMaterial(Material mat, Material.Modifier mod)
    {
        texture("material.colormap", 0, mat.colormap);
    }

    //-------------------------------------------------------------------------

    protected this(string conffile)
    {
        super(
            [
                conffile,
                "engine/render/scene3d/glsl/types.3d.glsl",
                "engine/render/scene3d/glsl/default3d.in.glsl",
            ], [
                "engine/render/scene3d/glsl/verts.lib.glsl",
                "engine/render/scene3d/glsl/flat3d.glsl",
            ], [
                "engine/render/scene3d/glsl/frags.lib.glsl",
                "engine/render/scene3d/glsl/flat3d.glsl",
            ]
        );
    }

    private this()
    {
        this(null);
    }
}

