//*****************************************************************************
//
// Instance combine vertex and material data
//
// TO BE REWORKED!
//
//*****************************************************************************

module engine.render.instance;

//-------------------------------------------------------------------------

import engine.render.util;
import engine.render.shaders.base;
import engine.render.bone;
import engine.render.view;

import engine.render.mesh;
import engine.render.bound;
import engine.render.material;
import engine.render.texture;

//-------------------------------------------------------------------------
// Shape combines shader vertex data (VAO, Vertex Array Object) with
// material info (color, colormap, ...)
//-------------------------------------------------------------------------

class Shape
{
    Shader.VAO vao;
    Material material;

    this(Shader.VAO vao, Material material)
    {
        this.vao = vao;
        this.material = material;
    }

    this(Shader shader, Mesh mesh, Material material)
    {
        this(shader.upload(mesh), material);
    }

    //-------------------------------------------------------------------------
    // "ShapeSheet" from "SpriteSheet"
    //-------------------------------------------------------------------------

    static Shape[][] sheet(
        Shader shader,
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
        auto grid = new Shape[][](rows, cols);

        foreach(y; 0 .. rows) foreach(x; 0 .. cols)
        {
            auto mesh = geom.rect(vec2(meshw, meshh), geom.center);

            mesh.uv_scale(vec2(uvw, uvh));
            mesh.uv_move(x * uvw, y * uvh);
            
            grid[y][x] = new Shape(shader, mesh, material);
        }

        return grid;
    }
}

//-------------------------------------------------------------------------
// Instances are drawable objects that combine "Bone" (transforms) with
// Shape
//-------------------------------------------------------------------------

class Instance : Bone
{
    Shape shape;

    //-------------------------------------------------------------------------

    this(Bone parent, vec3 pos, vec3 rot, Shape shape)
    {
        super(parent, pos, rot);
        this.shape = shape;
    }

    this(vec3 pos, Shape shape = null)
    {
        this(null, pos, vec3(0, 0, 0), shape);
    }

    this(vec3 pos, Shader.VAO vao, Material m)
    {
        this(null, pos, vec3(0, 0, 0), new Shape(vao, m));
    }

    this(Bone parent, Shape shape)
    {
        this(parent, vec3(0, 0, 0), vec3(0, 0, 0), shape);
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
        return (mModel() * vec4(v, 1)).xyz;
    }

    void project(View cam)
    {
        viewspace.pos = cam.viewspace(pos);

        viewspace.bsp = cam.viewspace(mModel(), shape.vao.bsp.center);
        viewspace.bspdst2 = viewspace.bsp.magnitude_squared;

        Frustum frustum = cam.frustum;

        viewspace.infrustum = INSIDE;
        foreach(plane; frustum.planes)
        {
            float dist = plane.distance(viewspace.bsp);
            if (dist < -shape.vao.bsp.radius)
            {
                viewspace.infrustum = OUTSIDE;
                break;
            }
            else if(dist < shape.vao.bsp.radius)
            {
                viewspace.infrustum = INTERSECT;
            }
        }
    }

    //-------------------------------------------------------------------------

    void render(Shader shader, View cam)
    {
        if(!shape) return;
        shader.render(cam, this, shape.material, shape.vao);
    }
}

