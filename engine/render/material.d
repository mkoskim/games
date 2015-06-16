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
    static class Modifier
    {
        vec4 color;

        this(vec4 color) { this.color = color; }
    }
    
    Texture colormap;
    Texture normalmap;

    //-------------------------------------------------------------------------
    // Material reflectivity is approximated with roughness coefficient. The
    // smoother material (smaller roughness), the more specular lightning.
    //-------------------------------------------------------------------------

    float roughness;

    //-------------------------------------------------------------------------

    this(Texture colormap, Texture normalmap, float roughness = 1.0)
    {
        static Texture whitemap = null;
        static Texture flatmap = null;

        if(!whitemap) whitemap = new Texture(vec4(1, 1, 1, 1));
        if(!flatmap)  flatmap  = new Texture(vec4(0.5, 0.5, 1, 1));

        this.colormap = colormap ? colormap : whitemap;
        this.normalmap = normalmap ? normalmap : flatmap;
        this.roughness = roughness;
    }

    //-------------------------------------------------------------------------

    this() { this(cast(Texture)null, cast(Texture)null); }

    //-------------------------------------------------------------------------

    this(string colormap, string normalmap, float roughness = 1.0)
    {
        this(new Texture(colormap), new Texture(normalmap), roughness);
    }

    this(vec4 color, Texture normalmap, float roughness = 1.0)
    {
        this(new Texture(color), normalmap, roughness);
    }

    this(vec4 color, string normalmap, float roughness = 1.0)
    {
        this(color, new Texture(normalmap), roughness);
    }

    this(Texture colormap, float roughness = 1.0)
    {
        this(colormap, null, roughness);
    }

    this(string colormap, float roughness = 1.0)
    {
        this(new Texture(colormap), roughness);
    }

    this(SDL_Surface *colormap, float roughness = 1.0)
    {
        this(new Texture(colormap), null, roughness);
    }

    this(vec4 color, float roughness = 1.0)
    {
        this(new Texture(color), null, roughness);
    }

    this(float r, float g, float b, float a = 1)
    {
        this(vec4(r, g, b, a));
    }

    //-------------------------------------------------------------------------
    // Creating materials from list of bitmaps, for example, to create
    // icons etc.
    //-------------------------------------------------------------------------

    static Material[] upload(Bitmap[] bitmaps)
    {
        Material[] list;
        foreach(texture; Texture.upload(bitmaps)) list ~= new Material(texture);
        return list;
    }
}

