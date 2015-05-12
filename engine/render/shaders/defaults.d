//*****************************************************************************
//
// Shader classes act as interface to GLSL shader program. They are (usually)
// singletons.
//
//*****************************************************************************

module engine.render.shaders.defaults;

import engine.render.shaders.base;
import engine.render.util;

import engine.render.bone;
import engine.render.mesh;
import engine.render.material;
import engine.render.texture;
import engine.render.view;
import engine.render.light;

//*****************************************************************************
//
// Simple shader base class
//
//*****************************************************************************

abstract class Default : Shader
{
    protected this(string[] common, string[] vsfiles, string[] fsfiles)
    {
        super(common, vsfiles, fsfiles);
    }
    protected this(string filename) { super(filename); }
    protected this(string vsfile, string fsfile) { super(vsfile, fsfile); }

    //-------------------------------------------------------------------------

    protected void bindMaterial(Material material)
    {
        uniform("material.color", material.color);
        texture("material.colormap", 0, material.colormap);
    }

    protected void bindMatrices(View cam, Bone grip)
    {
        uniform("mProjection", cam.mProjection());
        uniform("mModelView", cam.mModelView(grip.mModel()));
    }

    override void render(View cam, Bone grip, Material mat, VAO vao)
    {
        if(!enabled) return;

        bindMatrices(cam, grip);
        bindMaterial(mat);
        vao.draw();

        //bindMaterial(instance.shape.material);
        //instance.shape.vao.draw();
    }
}

//*****************************************************************************
//
// Simple 2D shader
//
//*****************************************************************************

class Default2D : Default
{
    static Shader create()
    {
        static Shader instance = null;
        if(!instance) instance = new Default2D();
        return instance;
    }

    //-------------------------------------------------------------------------

    private this()
    {
        super("engine/render/shaders/glsl/default2d.glsl");
    }

    //-------------------------------------------------------------------------

    protected override void apply()
    {
        super.apply();

        checkgl!glDisable(GL_CULL_FACE);
        checkgl!glDisable(GL_DEPTH_TEST);

        checkgl!glEnable(GL_BLEND);
        checkgl!glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        //checkgl!glBlendFunc(GL_SRC_COLOR, GL_ONE_MINUS_SRC_ALPHA);

        //glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    }

    //-------------------------------------------------------------------------

    override protected void addVBOs(VAO vao, Mesh mesh)
    {
        VBO vbo = new VBO(
            mesh.vertices.ptr,
            mesh.vertices.length,
            mesh.VERTEX.sizeof
        );

        attrib!(mesh.VERTEX.pos)(vbo, "vert_pos");
        attrib!(mesh.VERTEX.uv)(vbo, "vert_uv");

        vao.vbos = [ vbo ];
    }
}

//*****************************************************************************
//
// Simple 3D shader
//
//*****************************************************************************

class Default3D : Default
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
                "engine/render/shaders/glsl/types.3d.glsl",
                "engine/render/shaders/glsl/default3d.in.glsl",
            ], [
                "engine/render/shaders/glsl/verts.lib.glsl",
                "engine/render/shaders/glsl/verts.3d.glsl",
            ], [
                "engine/render/shaders/glsl/frags.lib.glsl",
                "engine/render/shaders/glsl/frags.3d.glsl",
            ]
        );
    }

    private this()
    {
        this(null);
    }

    //-------------------------------------------------------------------------

    protected override void apply()
    {
        super.apply();
        checkgl!glEnable(GL_CULL_FACE);
        checkgl!glFrontFace(GL_CCW);
        checkgl!glEnable(GL_DEPTH_TEST);

        checkgl!glDisable(GL_BLEND);
    }

    //-------------------------------------------------------------------------

    override void light(Light l)
    {
        uniform("light.pos", l.grip.pos);
        uniform("light.radius", l.radius);
        uniform("light.ambient", l.ambient);
        uniform("light.color", l.color);
    }

    //-------------------------------------------------------------------------

    override protected void addVBOs(VAO vao, Mesh mesh)
    {
        VBO vbo = new VBO(
            mesh.vertices.ptr,
            mesh.vertices.length,
            mesh.VERTEX.sizeof
        );

        attrib!(mesh.VERTEX.pos)(vbo, "vert_pos");
        attrib!(mesh.VERTEX.uv)(vbo, "vert_uv");
        attrib!(mesh.VERTEX.normal)(vbo, "vert_norm");
        attrib!(mesh.VERTEX.tangent)(vbo, "vert_tangent");

        vao.vbos = [ vbo ];
    }

    //-------------------------------------------------------------------------

    override void bindMaterial(Material material)
    {
        super.bindMaterial(material);
        texture("material.normalmap", 1, material.normalmap);
        uniform("material.roughness", material.roughness);
    }
}

//*****************************************************************************
//
// Lightless (just textures) 3D shader
//
//*****************************************************************************

class Lightless3D : Default2D
{
    static Shader create()
    {
        static Shader instance = null;
        if(!instance) instance = new Lightless3D();
        return instance;
    }

    //-------------------------------------------------------------------------

    protected override void apply()
    {
        super.apply();
        checkgl!glEnable(GL_CULL_FACE);
        checkgl!glFrontFace(GL_CCW);
        checkgl!glEnable(GL_DEPTH_TEST);

        checkgl!glDisable(GL_BLEND);
    }
}

//*****************************************************************************
//
// "Toon" shader
//
//*****************************************************************************

class Toon3D : Default3D
{
    static Shader create()
    {
        static Shader instance = null;
        if(!instance) instance = new Toon3D();
        return instance;
    }

    //-------------------------------------------------------------------------

    private this()
    {
        super("engine/render/shaders/glsl/conf.toon3d.glsl");
    }
}

