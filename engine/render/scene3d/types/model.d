//*****************************************************************************
//
// Model combine vertex data and material
//
//*****************************************************************************

module engine.render.scene3d.types.model;

//-------------------------------------------------------------------------

import engine.render.util;

import engine.render.loader.mesh;

import engine.render.scene3d.shader;
import engine.render.scene3d.types.transform;
//import engine.render.types.bound;
//import engine.render.types.texture;
import engine.render.scene3d.types.material;

//import engine.render.types.view;
//import engine.render.batch;

//*****************************************************************************
//
// Renderable: These classes know how to send themselves to shader.
//
//*****************************************************************************

//-------------------------------------------------------------------------
// Model combines shader vertex data (VAO, Vertex Array Object) with
// material info (colormap, ...)
//-------------------------------------------------------------------------

class Model
{
    Shader.VAO vao;
    Material material;

    this(Shader.VAO vao, Material material)
    {
        this.vao = vao;
        this.material = material;
    }

    //-------------------------------------------------------------------------
    // "ShapeSheet" from "SpriteSheet": TODO - this sort of mechanism
    // is used for instanced (sprite) blitting from texture atlas.
    //-------------------------------------------------------------------------

/*
    static Model[][] sheet(
        Batch batch,
        Texture sheet,
        int texw, int texh,
        float meshw = 1.0, float meshh = 1.0,
        int padx = 0, int pady = 0
    )
    {
        import geom = engine.ext.geom;

        int cols = sheet.width / (texw+padx);
        int rows = sheet.height / (texh+pady);
        
        float uvw = texw / cast(float)sheet.width;
        float uvh = texh / cast(float)sheet.height;

        auto material = new Material(sheet, 1.0);   // TODO: Determine roughness
        auto grid = new Model[][](rows, cols);

        foreach(y; 0 .. rows) foreach(x; 0 .. cols)
        {
            auto mesh = geom.rect(vec2(meshw, meshh), geom.center);

            mesh.uv_scale(vec2(uvw, uvh));
            mesh.uv_move(x * uvw, y * uvh);
            
            grid[y][x] = batch.upload(mesh, material);
        }

        return grid;
    }
*/
}

