//*****************************************************************************
//
// Materials for rendering
//
// TO BE REWORKED! Objects have object-specific modifiers (e.g. color
// modifier).
//
//*****************************************************************************

module engine.render.scene3d.types.material;

//-----------------------------------------------------------------------------

import engine.render.util;
import engine.render.gpu.texture;

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

        if(whitemap is null) whitemap = Texture.Loader.Default(vec4(1, 1, 1, 1));
        if(flatmap is null)  flatmap  = Texture.Loader.Default(vec4(0.5, 0.5, 1, 1));

        this.colormap = colormap ? colormap : whitemap;
        this.normalmap = normalmap ? normalmap : flatmap;
        this.roughness = roughness;
    }

    //-------------------------------------------------------------------------
    
    static class Loader
    {
        Texture.Loader ColorMap;
        Texture.Loader NormalMap;
        
        this()
        {
            ColorMap = (new Texture.Loader())
                .setMipmap(true)
                .setFiltering(GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR)
                .setCompress(true)
            ;
            NormalMap = (new Texture.Loader())
                .setMipmap(true)
                .setFiltering(GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR)
            ;
        }
        
        this(Texture.Loader colormap, Texture.Loader normalmap)
        {
            this.ColorMap = colormap;
            this.NormalMap = normalmap;
        }

        //---------------------------------------------------------------------

        Material opCall() { return new Material(null, null); }

        Material opCall(Texture colormap, Texture normalmap, float roughness = 1.0)
        {
            return new Material(colormap, normalmap, roughness);
        }

        // Materials without normal maps --------------------------------------
        
        Material opCall(string colormap, float roughness = 1.0)
        {
            return this.opCall(ColorMap(colormap), null, roughness);
        }

        Material opCall(Bitmap colormap, float roughness = 1.0)
        {
            return this.opCall(ColorMap(colormap), null, roughness);
        }

        Material opCall(vec4 color, float roughness = 1.0)
        {
            return this.opCall(ColorMap(color), null, roughness);
        }

        // Materials with normal maps -----------------------------------------
        
        Material opCall(string colormap, string normalmap, float roughness = 1.0)
        {
            return this.opCall(ColorMap(colormap), NormalMap(normalmap), roughness);
        }

        Material opCall(vec4 color, string normalmap, float roughness = 1.0)
        {
            return this.opCall(ColorMap(color), NormalMap(normalmap), roughness);
        }

        Material opCall(string colormap, Texture normalmap, float roughness = 1.0)
        {
            return this.opCall(ColorMap(colormap), normalmap, roughness);
        }

        Material opCall(vec4 color, Texture normalmap, float roughness = 1.0)
        {
            return this.opCall(ColorMap(color), normalmap, roughness);
        }
    }    
}

