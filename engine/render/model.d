//*****************************************************************************
//
// Model combine vertex and material with transform
//
// TO BE REWORKED! Instances are related to 'Batches' or layers or such.
// Different layers may hold different kind of instance data.
//
// Furthermore, instances itselves have their pecularities. Some instances
// may have LOD levels, meaning that the actual shape to render depends on
// the distance of the object.
//
// And furthermore, there are different kind of 'strategies' for rendering
// game scenes. Depending on the content, e.g.
//
// - Use instanced draw
// - Sort drawing order (back to front, front to back)
// - Frustum culling
// - Portals and occluders
// - BSP etc
//
//*****************************************************************************

module engine.render.model;

//-------------------------------------------------------------------------

import engine.render.util;

import engine.render.shaders.base;
import engine.render.bone;
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

    /*
    this(Shader shader, Mesh mesh, Material material)
    {
        Shader.VAO vao = mesh ? shader.upload(mesh) : null;
        this(vao, material);
    }
    */

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

//-------------------------------------------------------------------------
// Nodes are drawable objects that combine "Bone" (transforms) with
// Shape
//-------------------------------------------------------------------------

class Node
{
    //-------------------------------------------------------------------------

    Model model;
    Bone grip;

    //-------------------------------------------------------------------------

    this(Bone parent, vec3 pos, vec3 rot, Model model)
    {
        this.grip = new Bone(parent, pos, rot);
        this.model = model;
    }

    this(vec3 pos, Model model = null)
    {
        this(null, pos, vec3(0, 0, 0), model);
    }

    this(Bone parent, Model model = null)
    {
        this(parent, vec3(0, 0, 0), vec3(0, 0, 0), model);
    }

    //-------------------------------------------------------------------------
    // Cached values from rendering phase
    //-------------------------------------------------------------------------

    struct VIEWSPACE {
        vec3 pos;		// Position relative to camera

        vec3 bsp;		// Bounding sphere position relative to camera
        float bspdst2;	// Bouding sphere (squared) distance to camera

        int infrustum;	// = INSIDE, INTERSECT or OUTSIDE
    }

    VIEWSPACE viewspace;

    vec3 transform(vec3 v)
    {
        return (grip.mModel() * vec4(v, 1)).xyz;
    }

    void project(View cam)
    {
        viewspace.pos = cam.viewspace(grip.mModel());

        viewspace.bsp = cam.viewspace(grip.mModel(), model.vao.bsp.center);
        viewspace.bspdst2 = viewspace.bsp.magnitude_squared;

        Frustum frustum = cam.frustum;

        viewspace.infrustum = INSIDE;
        foreach(plane; frustum.planes)
        {
            float dist = plane.distance(viewspace.bsp);
            if (dist < -model.vao.bsp.radius)
            {
                viewspace.infrustum = OUTSIDE;
                break;
            }
            else if(dist < model.vao.bsp.radius)
            {
                viewspace.infrustum = INTERSECT;
            }
        }
    }
}

