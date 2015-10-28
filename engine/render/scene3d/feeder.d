//*****************************************************************************
//
// (Shader) Feeder for 3D nodes.
//
//*****************************************************************************

module engine.render.scene3d.feeder;

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

//-----------------------------------------------------------------------------
//
// Feeder object to feed 3D nodes to (hopefully suitable) shader. We now
// implement this as an abstract class from which Batches are inherited,
// but we might want to change this pluggable (composition) later.
//
//-----------------------------------------------------------------------------

class Feeder
{
    protected gpu.State state;

    this(gpu.State state)
    {
        this.state = state;
    }

    //-------------------------------------------------------------------------

    void activate() { state.activate(); }
    auto shader() { return state.shader; }

    //*************************************************************************
    //
    // Load camera. NOTE: I use term 'load' instead of 'set' to indicate that
    // these operations are relatively costly.
    //
    //*************************************************************************

    void loadView(View cam)
    {
        shader.uniform("mProjection", cam.mProjection());
        shader.uniform("mView", cam.mView());
    }

    //*************************************************************************
    //
    // Lights (TODO: Just a hack)
    //
    //*************************************************************************

    void loadLight(Light l)
    {
        shader.uniform("light.pos", l.transform.worldspace());

        shader.uniform("light.radius", l.radius);
        shader.uniform("light.ambient", l.ambient);
        shader.uniform("light.color", l.color);
    }

    //*************************************************************************
    //
    // Rendering
    //
    //*************************************************************************

    void loadMaterial(Material mat, Material.Modifier mod)
    {
        shader.texture("material.colormap", 0, mat.colormap);
        shader.texture("material.normalmap", 1, mat.normalmap);

        shader.uniform("material.roughness", mat.roughness);

        if(mod is null) {
            shader.uniform("material.modifier.color", vec4(1, 1, 1, 1));
        }
        else {
            shader.uniform("material.modifier.color", mod.color);
        }
    }

    //*************************************************************************
    //
    // Rendering objects
    //
    //*************************************************************************

    void render(mat4 transform, VAO vao)
    {
        shader.uniform("mModel", transform);

        vao.vao.bind();
        vao.ibo.draw();
        vao.vao.unbind();
    }

    void render(Transform[] transforms, VAO vao)
    {
        vao.vao.bind();
        foreach(transform; transforms)
        {
            shader.uniform("mModel", transform.mModel());
            vao.ibo.draw();
        }
        vao.vao.unbind();
    }

    //-------------------------------------------------------------------------

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

    final void render(Transform transform, VAO vao)
    {
        render(transform.mModel(), vao);
    }

    //*************************************************************************
    //
    // Uploading mesh to GPU
    //
    //*************************************************************************

    protected class VAO
    {
        Feeder target;
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

        vao.target = this;

        vao.vao = new gpu.VAO();
        vao.vao.bind();

        vao.vbo = new gpu.VBO(
            vertbuf.ptr,
            vertbuf.length,
            VERTEX.sizeof
        );
        vao.vbo.bind();

        shader.attrib!(VERTEX.pos)(shader, "vert_pos", VERTEX.sizeof);
        shader.attrib!(VERTEX.uv)(shader, "vert_uv", VERTEX.sizeof);
        shader.attrib!(VERTEX.normal)(shader, "vert_norm", VERTEX.sizeof);
        shader.attrib!(VERTEX.tangent)(shader, "vert_tangent", VERTEX.sizeof);

        vao.bsp = BoundSphere.create(mesh);

        vao.ibo = new gpu.IBO(mesh.mode, mesh.faces);
        vao.ibo.bind();

        vao.vao.unbind();
        vao.vbo.unbind();
        vao.ibo.unbind();

        return vao;
    }
}

//*****************************************************************************
//
// Some 3D shaders and rendering states... Bad thing: these names conflict
// with GPU side names, so extra careful is needed. Needs to be changed at
// some point. But anyways, when creating new ways to utilize shaders, you
// probably want to encapsulate shader creation, too.
//
//*****************************************************************************

abstract class Shader
{
    private static gpu.Shader create(string conffile, string vertmain, string fragmain = null)
    {
        if(!fragmain) fragmain = vertmain;
        return new gpu.Shader(
            [
                conffile,
                "engine/render/scene3d/glsl/types.3d.glsl",
                "engine/render/scene3d/glsl/default3d.in.glsl",
            ], [
                "engine/render/scene3d/glsl/verts.lib.glsl",
                vertmain,
            ], [
                "engine/render/scene3d/glsl/frags.lib.glsl",
                fragmain,
            ]
        );
    }

    static gpu.Shader Default3D(string conffile = null)
    {
        static gpu.Shader instance = null;
        if(!instance) instance = create(
            conffile,
            "engine/render/scene3d/glsl/verts.3d.glsl",
            "engine/render/scene3d/glsl/frags.3d.glsl"
        );
        return instance;
    }

    static gpu.Shader Flat3D(string conffile = null)
    {
        static gpu.Shader instance = null;
        if(!instance) {
            instance = create(conffile, "engine/render/scene3d/glsl/flat3d.glsl");
            instance.setRejected([
                "vert_norm", "vert_tangent",
                "light.pos", "light.color", "light.radius", "light.ambient",
            ]);
        }
        return instance;
    }
}

abstract class State
{
    static gpu.State Solid3D(gpu.Shader shader = Shader.Default3D())
    {
        return new gpu.State(shader, (){
            checkgl!glEnable(GL_CULL_FACE);
            checkgl!glCullFace(GL_BACK);
            checkgl!glFrontFace(GL_CCW);
            checkgl!glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            checkgl!glEnable(GL_DEPTH_TEST);
            checkgl!glDisable(GL_BLEND);
        });
    }

    static gpu.State Transparent3D(gpu.Shader shader = Shader.Default3D())
    {
        return new gpu.State(shader, (){
            checkgl!glEnable(GL_CULL_FACE);
            checkgl!glCullFace(GL_BACK);
            checkgl!glFrontFace(GL_CCW);
            checkgl!glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

            checkgl!glEnable(GL_DEPTH_TEST);
            checkgl!glEnable(GL_BLEND);
            checkgl!glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        });
    }
}

