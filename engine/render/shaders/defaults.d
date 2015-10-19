//*****************************************************************************
//
// Shader classes act as interface to GLSL shader program. They are (usually)
// singletons.
//
//*****************************************************************************

module engine.render.shaders.defaults;

import engine.render.util;

import engine.render.shaders.base;
import engine.render.gpu.mesh;

import engine.render.transform;
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

    override void loadView(View cam)
    {
        uniform("mProjection", cam.mProjection());
        uniform("mView", cam.mView());
    }

    override void loadMaterial(Material mat, Material.Modifier mod)
    {
        texture("material.colormap", 0, mat.colormap);
        if(mod is null) {
            uniform("material.modifier.color", vec4(1, 1, 1, 1));
        }
        else {
            uniform("material.modifier.color", mod.color);
        }
    }
    
    //-------------------------------------------------------------------------

    override void render(mat4 transform, VAO vao)
    {
        uniform("mModel", transform);

        vao.bind();
        vao.ibo.draw();
        vao.unbind();
    }

    override void render(Transform[] transforms, VAO vao)
    {
        vao.bind();
        foreach(transform; transforms)
        {
            uniform("mModel", transform.mModel());
            vao.ibo.draw();
        }
        vao.unbind();
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

        attributes = [ "vert_pos", "vert_uv" ];
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

        attributes = [
            "vert_pos", "vert_uv",
            "vert_norm", "vert_tangent",
        ];
    }

    private this()
    {
        this(null);
    }

    //-------------------------------------------------------------------------

    override void light(Light l)
    {
        uniform("light.pos", l.transform.worldspace());

        uniform("light.radius", l.radius);
        uniform("light.ambient", l.ambient);
        uniform("light.color", l.color);
    }

    //-------------------------------------------------------------------------

    override void loadMaterial(Material mat, Material.Modifier mod)
    {
        super.loadMaterial(mat, mod);
        texture("material.normalmap", 1, mat.normalmap);
        uniform("material.roughness", mat.roughness);
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

    private this()
    {
        super("engine/render/shaders/glsl/conf.toon3d.glsl");
    }
}

