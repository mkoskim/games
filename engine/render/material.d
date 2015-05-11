//*****************************************************************************
//
// Materials for rendering
//
// TO BE REWORKED! Objects have object-specific modifiers (e.g. color
// modifier).
//
//*****************************************************************************

module engine.render.material;

//-----------------------------------------------------------------------------

import engine.render.util;
import engine.render.texture;

//-----------------------------------------------------------------------------
//
// One thing to keep in mind is that material parameters should be "shader
// independend", that is, the actual shading model parameters are calculated
// elsewhere.
//
//-----------------------------------------------------------------------------

class Material
{
    vec4 color;
    Texture colormap;
    Texture normalmap;

    //-------------------------------------------------------------------------
    // Material reflectivity is approximated with roughness coefficient. The
    // smoother material (smaller roughness), the more specular lightning.
    //-------------------------------------------------------------------------

    float roughness;

    //-------------------------------------------------------------------------

    static Texture whitemap = null;
    static Texture flatmap = null;

    this()
    {
        if(!whitemap) whitemap = new Texture(vec4(1, 1, 1, 1));
        if(!flatmap)  flatmap  = new Texture(vec4(0.5, 0.5, 1, 1));

        color = vec4(1, 1, 1, 1);
        colormap = whitemap;
        normalmap = flatmap;
        roughness = 0.5;
    }

    //-------------------------------------------------------------------------

    this(Texture colormap, Texture normalmap, float roughness)
    {
        this();
        this.colormap = colormap;
        this.normalmap = normalmap;
        this.roughness = roughness;
    }

    this(vec3 color, Texture normalmap, float roughness)
    {
        this();
        this.color = vec4(color, 1);
        this.normalmap = normalmap;
        this.roughness = roughness;
    }

    this(Texture colormap, float roughness)
    {
        this();
        this.colormap = colormap;
        this.roughness = roughness;
    }

    this(SDL_Surface *colormap, float roughness)
    {
        this();
        this.colormap = new Texture(colormap);
        this.roughness = roughness;
    }

    this(vec3 color, float roughness)
    {
        this();
        this.color = vec4(color, 1);
        this.roughness = roughness;
    }

    //-------------------------------------------------------------------------

    this(vec4 color)
    {
        this();
        this.color = color;
    }

    this(float r, float g, float b, float a = 1)
    {
        this(vec4(r, g, b, a));
    }

    this(Texture tex)
    {
        this();
        this.colormap = tex;
    }

    this(SDL_Surface *surface)
    {
        this();
        this.colormap = new Texture(surface);
    }
}

