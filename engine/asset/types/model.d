//*****************************************************************************
//
// Model combine vertex data and material
//
//*****************************************************************************

module engine.asset.types.model;

//-------------------------------------------------------------------------

import engine.asset.util;

import engine.asset.types.mesh;

import engine.asset.types.transform;
import engine.asset.types.material;

// TODO: Get rid of this
import engine.render.scene3d.batch: Batch;

//-------------------------------------------------------------------------
// Model combines shader vertex data (VAO, Vertex Array Object) with
// material info (colormap, ...). It also contains info where to send
// it during rendering.
//-------------------------------------------------------------------------

class Model
{
    Batch.VAO vao;
    Material material;

    this(Batch.VAO vao, Material material)
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

