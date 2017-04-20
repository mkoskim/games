//*****************************************************************************
//
// Textures
//
//*****************************************************************************

module engine.gpu.texture;

//-----------------------------------------------------------------------------

public import engine.asset.bitmap;

import engine.gpu.util;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
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
    GLint w, GLint h,
    GLint mipmap_levels,
    GLenum format,
    GLenum type,
    void* buffer,
    bool compress
)
{
    checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
    checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, mipmap_levels);

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
        0,
        intformat,
        w, h,
        0,
        format,
        type,
        buffer
    );

    if(mipmap_levels) checkgl!glGenerateMipmap(target);
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
        static Loader Compressed;

        static this() {
            Default    = new Loader();
            Compressed = new Loader().setCompress(true);
        }

        //----------------------------------------------------------------------

        struct FILTERING { GLenum mag, min; }
        struct WRAPPING  { GLenum s, t; }

        FILTERING filtering;
        WRAPPING wrapping;

        bool compress;

        //----------------------------------------------------------------------

        this() {
            compress = false;
            filtering = FILTERING(GL_LINEAR, GL_LINEAR_MIPMAP_LINEAR);
            wrapping  = WRAPPING(GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE);
        }

        //---------------------------------------------------------------------

        Loader setFiltering(GLenum mag, GLenum min) {
            filtering.mag = mag;
            filtering.min = min;
            return this;
        }

        Loader setWrapping(GLenum s, GLenum t) {
            wrapping.s = s;
            wrapping.t = t;
            return this;
        }

        Loader setCompress(bool state) {
            compress = state;
            return this;
        }

        Loader setMipmap(bool state) {
            filtering.mag = state ? GL_LINEAR_MIPMAP_LINEAR : GL_LINEAR;
            return this;
        }

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

        //---------------------------------------------------------------------
        // CPU-side bitmap to texture
        //---------------------------------------------------------------------

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
        debug Track.add(this);

        width = w;
        height = h;

        //---------------------------------------------------------------------

        //TODO("Alpha maps not working");

        //---------------------------------------------------------------------

        checkgl!glGenTextures(1, &ID);

        checkgl!glBindTexture(GL_TEXTURE_2D, ID);

        //---------------------------------------------------------------------
        // Set up texture sampling
        //---------------------------------------------------------------------
        
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, loader.filtering.mag);
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, loader.filtering.min);

        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, loader.wrapping.s);
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, loader.wrapping.t);
        //checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, loader.wrapping.r);

        //---------------------------------------------------------------------

        int mipmap_levels = 0;
        
        switch(loader.filtering.min)
        {
            case GL_LINEAR_MIPMAP_LINEAR:
            case GL_LINEAR_MIPMAP_NEAREST:
            case GL_NEAREST_MIPMAP_LINEAR:
            case GL_NEAREST_MIPMAP_NEAREST:
                import std.math: log2, fmax;
                mipmap_levels = cast(int)log2(fmax(width, height)) - 4;
                if(mipmap_levels < 0) mipmap_levels = 0;
                break;
            default: break;
        }
        
        //---------------------------------------------------------------------
        // Upload texture data to GPU
        //---------------------------------------------------------------------

        uploadTextureData(
            GL_TEXTURE_2D,
            w, h,
            mipmap_levels,      // Mipmap levels
            format,             // Format of data
            type,               // Data type/width
            buffer,             // Actual data
            loader.compress
        );

        //---------------------------------------------------------------------

        checkgl!glBindTexture(GL_TEXTURE_2D, 0);
    }

    //-------------------------------------------------------------------------

    ~this()
    {
        debug Track.remove(this);
        glDeleteTextures(1, &ID);
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
                return GLenumName[getlvlparam(GL_TEXTURE_INTERNAL_FORMAT)];
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

    private this(SDL_Surface*[] surfaces)
    {
        debug Track.add(this);

        checkgl!glGenTextures(1, &ID);
        checkgl!glBindTexture(GL_TEXTURE_CUBE_MAP, ID);

        foreach(i; 0 .. 6) uploadTextureData(
            GL_TEXTURE_CUBE_MAP_POSITIVE_X + i,
            surfaces[i].w, surfaces[i].h,
            0,
            _GLformat(surfaces[i]),
            GL_UNSIGNED_BYTE,
            surfaces[i].pixels,
            true
        );

        checkgl!glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        checkgl!glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

        checkgl!glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        checkgl!glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        checkgl!glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

        checkgl!glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    }

    ~this()
    {
        debug Track.remove(this);
        glDeleteTextures(1, &ID);
    }
}


