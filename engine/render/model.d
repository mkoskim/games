//*****************************************************************************
//
// Model combine vertex and material with transform
//
//*****************************************************************************

module engine.render.model;

//-------------------------------------------------------------------------

import engine.render.util;

import engine.render.shaders.base;
import engine.render.transform;
import engine.render.mesh;
import engine.render.bound;
import engine.render.texture;
import engine.render.material;
import engine.render.view;
import engine.render.batch;

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
    // "ShapeSheet" from "SpriteSheet": This is better than the old one,
    // but could be improved by moving it to somewhere else.
    //-------------------------------------------------------------------------

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
}

