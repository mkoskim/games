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
// elsewhere (for example, in corresponding Shader class implementation).
//
// Note: This material scheme is aimed for textured objects. Creating
// solid color objects require to create (single pixel) solid color
// texture. The assumption is that solid color objects are temporal
// placeholders, and rare in later phases of game development.
//
//-----------------------------------------------------------------------------

class Material
{
    Texture colormap;
    Texture normalmap;

    //-------------------------------------------------------------------------
    // Material reflectivity is approximated with roughness coefficient. The
    // smoother material (smaller roughness), the more specular lightning.
    //-------------------------------------------------------------------------

    float roughness;

    //-------------------------------------------------------------------------

    private static Texture whitemap = null;
    private static Texture flatmap = null;

    //-------------------------------------------------------------------------

    this(Texture colormap, Texture normalmap, float roughness = 1.0)
    {
        if(!whitemap) whitemap = new Texture(vec4(1, 1, 1, 1));
        if(!flatmap)  flatmap  = new Texture(vec4(0.5, 0.5, 1, 1));

        this.colormap = colormap ? colormap : whitemap;
        this.normalmap = normalmap ? normalmap : flatmap;
        this.roughness = roughness;
    }

    //-------------------------------------------------------------------------

    this(vec4 color, Texture normalmap, float roughness)
    {
        this(new Texture(color), normalmap, roughness);
    }

    this(Texture colormap, float roughness)
    {
        this(colormap, null, roughness);
    }

    this(SDL_Surface *colormap, float roughness)
    {
        this(new Texture(colormap), null, roughness);
    }

    this(vec4 color, float roughness)
    {
        this(new Texture(color), null, roughness);
    }

    //-------------------------------------------------------------------------

    this(vec4 color)
    {
        this(new Texture(color), null);
    }

    this(float r, float g, float b, float a = 1)
    {
        this(vec4(r, g, b, a));
    }

    //-------------------------------------------------------------------------

    this(Texture tex)
    {
        this(tex, null);
    }

    this(SDL_Surface *surface)
    {
        this(new Texture(surface));
    }
}

