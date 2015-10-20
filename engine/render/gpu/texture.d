//*****************************************************************************
//
// Textures
//
//*****************************************************************************

module engine.render.gpu.texture;

//-----------------------------------------------------------------------------

public import engine.ext.bitmap;

import engine.render.util;
import blob = engine.blob;

import derelict.sdl2.sdl;
import std.algorithm;

//-----------------------------------------------------------------------------
// Try to determine suitable texture format
//-----------------------------------------------------------------------------

private GLuint _GLformat(SDL_Surface *surface)
{
    //debug writeln(SDL_PIXELORDER(surface.format.format));

    auto nbOfColors = surface.format.BytesPerPixel;

    switch (nbOfColors) {
        /*
        case 1:
            return GL_ALPHA;
        */
        case 3:     // no alpha channel
            if (surface.format.Rmask == 0x000000ff)
                return GL_RGB;
            else
                return GL_BGR;
        case 4:     // contains an alpha channel
            if (surface.format.Rmask == 0x000000ff)
                return GL_RGBA;
            else
                return GL_BGRA;
        default:
            return GL_RGB;
    }
}

//-----------------------------------------------------------------------------
// Normal 2D texture
//-----------------------------------------------------------------------------

private void uploadTextureData(
    GLenum target,
    GLint level,
    GLint w, GLint h,
    GLenum format,
    GLenum type,
    void* buffer,
    bool compress
)
{
    GLenum intformat;

    final switch(format)
    {
        
        case GL_BGRA:
        case GL_RGBA:
            format = GL_RGBA;
            intformat = compress ? GL_COMPRESSED_RGBA : format;
            break;
        
        case GL_RGB8:
        case GL_RGB:
            format = GL_RGB;
            intformat = compress ? GL_COMPRESSED_RGB : format;
            break;
    }

    checkgl!glTexImage2D(
        target,
        level,              // Mipmap level
        intformat,          // Internal format
        w, h,
        0,                  // Border
        format,             // Format of data
        type,               // Data type/width
        buffer              // Actual data
    );
}

//-----------------------------------------------------------------------------
// Normal 2D texture
//-----------------------------------------------------------------------------

class Texture
{
    GLuint ID;

    //-------------------------------------------------------------------------

    uint width, height;

    vec2 size() { return vec2(width, height); }

    //-------------------------------------------------------------------------
    // Texture loader / sampling parameters
    //-------------------------------------------------------------------------
    
    static class Loader
    {
        static Loader Default;

        static this() { Default = new Loader(); }

        //----------------------------------------------------------------------

        struct FILTERING { GLenum min, mag; }
        struct WRAPPING { GLenum s, t; }

        FILTERING filtering;
        WRAPPING wrapping;

        bool mipmap;
        bool compress;

        //----------------------------------------------------------------------

        this() {
            filtering = FILTERING(GL_LINEAR, GL_LINEAR);
            wrapping  = WRAPPING(GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE);
            mipmap = false;
            compress = false;
        }

        //---------------------------------------------------------------------
        // SDL surface to texture
        //---------------------------------------------------------------------

        Texture opCall(SDL_Surface *surface)
        {
            return new Texture(
                this,
                surface.w, surface.h,
                surface.pixels,
                _GLformat(surface)
            );
        }

        Texture opCall(Bitmap bitmap) { return opCall(bitmap.surface); }

        //-------------------------------------------------------------------------
        // Loading texture from blob file
        //-------------------------------------------------------------------------

        Texture opCall(string filename)
        {
            return opCall(new Bitmap(filename));
        }

        //-------------------------------------------------------------------------
        // Creating single pixel "dummy" textures
        //-------------------------------------------------------------------------

        Texture opCall(vec4 color)
        {
            return new Texture(this, 1, 1, cast(void*)color.value_ptr, GL_RGBA, GL_FLOAT);
        }

        //-------------------------------------------------------------------------
        // Texture sheets
        //-------------------------------------------------------------------------

        Texture[] opCall(Bitmap[] bitmaps)
        {
            Texture[] row;
            foreach(bitmap; bitmaps) row ~= opCall(bitmap);
            return row;
        }

        Texture[][] opCall(Bitmap[][] bitmaps)
        {
            Texture[][] grid;
            
            foreach(row; bitmaps) grid ~= opCall(row);

            return grid;
        }
    }

    //-------------------------------------------------------------------------
    // Creating texture from pixel data buffer
    //-------------------------------------------------------------------------

    this(Loader loader, uint w, uint h, void* buffer, GLenum format, GLenum type = GL_UNSIGNED_BYTE)
    {
        Track.add(this);

        width = w;
        height = h;

        //---------------------------------------------------------------------

        //TODO("Alpha maps not working");

        //---------------------------------------------------------------------

        //debug writeln("Format: ", _name[format], " internal: ", _name[intformat]);

        checkgl!glGenTextures(1, &ID);

        checkgl!glBindTexture(GL_TEXTURE_2D, ID);

        uploadTextureData(
            GL_TEXTURE_2D,
            0,                  // Mipmap level
            w, h,
            format,             // Format of data
            type,               // Data type/width
            buffer,             // Actual data
            loader.compress
        );

        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, loader.filtering.mag);
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, loader.filtering.min);

        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, loader.wrapping.s);
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, loader.wrapping.t);
        //checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, loader.wrapping.r);

        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);

        if(loader.mipmap) {
            import std.math: log2, fmax;
            int levels = cast(int)log2(fmax(width, height)) - 4;
            if(levels > 0) {
                checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, levels);
                checkgl!glGenerateMipmap(GL_TEXTURE_2D);
            }
        }

        checkgl!glBindTexture(GL_TEXTURE_2D, 0);
    }

    //-------------------------------------------------------------------------

    ~this()
    {
        Track.remove(this);
        glDeleteTextures(1, &ID);
    }

    //-------------------------------------------------------------------------

    debug private static const string[GLenum] formatname;

    static this() {
        debug formatname = [
            GL_BGRA: "GL_BGRA",
            GL_RGBA: "GL_RGBA",
            GL_BGR: "GL_BGR",
            GL_RGB: "GL_RGB",

            GL_RGB8: "GL_RGB8",

            GL_COMPRESSED_RGB: "GL_COMPRESSED_RGB",
            GL_COMPRESSED_RGBA: "GL_COMPRESSED_RGBA",

            GL_COMPRESSED_RGB_S3TC_DXT1_EXT: "GL_COMPRESSED_RGB_S3TC_DXT1",
            GL_COMPRESSED_RGBA_S3TC_DXT1_EXT: "GL_COMPRESSED_RGBA_S3TC_DXT1",
            GL_COMPRESSED_RGBA_S3TC_DXT3_EXT: "GL_COMPRESSED_RGBA_S3TC_DXT3",
            GL_COMPRESSED_RGBA_S3TC_DXT5_EXT: "GL_COMPRESSED_RGBA_S3TC_DXT5",

            0x86B0: "GL_COMPRESSED_RGB_FXT1_3DFX",
            0x86B1: "GL_COMPRESSED_RGBA_FXT1_3DFX",
        ];
    }

    //-------------------------------------------------------------------------
    // Print out information (for e.g. debugging purposes)
    //-------------------------------------------------------------------------

    void info()
    {
        GLint getparam(GLenum param) {
            GLint value;
            checkgl!glGetTexParameteriv(GL_TEXTURE_2D, param, &value);
            return value;
        }

        GLint getlvlparam(GLenum param, int lvl = 0) {
            GLint value;
            checkgl!glGetTexLevelParameteriv(GL_TEXTURE_2D, lvl, param, &value);
            return value;
        }

        string getformatname() {
            import core.exception: RangeError;
            try {
                return formatname[getlvlparam(GL_TEXTURE_INTERNAL_FORMAT)];
            }
            catch(RangeError e) {
                return to!string(getlvlparam(GL_TEXTURE_INTERNAL_FORMAT));
            }
        }

        checkgl!glBindTexture(GL_TEXTURE_2D, ID);

        writeln("ID...........: ", ID);
        writeln("- Dimensions.: ", getlvlparam(GL_TEXTURE_WIDTH), " x ", getlvlparam(GL_TEXTURE_HEIGHT));
        writeln("- Levels.....: ", getparam(GL_TEXTURE_MAX_LEVEL));
        writeln("- Format.....: ", getformatname());
        if(getlvlparam(GL_TEXTURE_COMPRESSED)) {
            writeln("- Size.......: ", getlvlparam(GL_TEXTURE_COMPRESSED_IMAGE_SIZE));
        }

        checkgl!glBindTexture(GL_TEXTURE_2D, 0);
    }
}

//-----------------------------------------------------------------------------
// Cubemap
//-----------------------------------------------------------------------------

class Cubemap
{
    GLuint ID;

    private void uploadFace(GLenum face, SDL_Surface* surface)
    {
        uploadTextureData(
            face,
            0,
            surface.w, surface.h,
            _GLformat(surface),
            GL_UNSIGNED_BYTE,
            surface.pixels,
            true
        );
    }

    this(SDL_Surface*[] surfaces)
    {
        Track.add(this);

        checkgl!glGenTextures(1, &ID);
        checkgl!glBindTexture(GL_TEXTURE_CUBE_MAP, ID);

        foreach(i; 0 .. 6) uploadFace(
            GL_TEXTURE_CUBE_MAP_POSITIVE_X + i,
            surfaces[i]
        );

        checkgl!glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        checkgl!glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

        checkgl!glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        checkgl!glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        checkgl!glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

        checkgl!glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    }

    this(Bitmap[] bitmaps)
    {
        SDL_Surface*[] surfaces;
        foreach(bitmap; bitmaps) surfaces ~= bitmap.surface;
        this(surfaces);
    }

    this(string[] filenames)
    {
        Bitmap[] bitmaps;
        foreach(filename; filenames) bitmaps ~= new Bitmap(filename);
        this(bitmaps);
    }
    
    ~this()
    {
        Track.remove(this);
        glDeleteTextures(1, &ID);
    }
}


