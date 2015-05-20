//*****************************************************************************
//
// Textures
//
// TODO: Implement mipmapping
// TODO: Experiment texture compression
//
//*****************************************************************************

module engine.render.texture;

//-----------------------------------------------------------------------------
// Try to determine suitable texture format
//-----------------------------------------------------------------------------

import engine.render.util;
import blob = engine.blob;

import derelict.sdl2.sdl;

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
//
//-----------------------------------------------------------------------------

class Texture
{
    GLuint ID;

    uint width, height;

    //-------------------------------------------------------------------------
    // Creating texture from byte buffer
    //-------------------------------------------------------------------------

    this(uint w, uint h, void* buffer, GLenum format)
    {
        const string[GLenum] _name = [
            GL_BGRA: "GL_BGRA",
            GL_RGBA: "GL_RGBA",
            GL_BGR: "GL_BGR",
            GL_RGB: "GL_RGB",
            
            GL_RGB8: "GL_RGB8",

            GL_COMPRESSED_RGB: "GL_COMPRESSED_RGB",
            GL_COMPRESSED_RGBA: "GL_COMPRESSED_RGBA",
        ];
        
        GLenum internal;
        GLenum data_width = GL_UNSIGNED_BYTE;
        GLint align_unpack;

        final switch(format)
        {
            // TODO: BGR(A) formats seem not to work
            case GL_BGRA: format = GL_RGBA; goto case GL_RGBA;
            case GL_BGR: format = GL_RGB; goto case GL_RGB;
                
            case GL_RGB8: format = GL_RGB; goto case GL_RGB;
            
            case GL_RGBA:
                internal = GL_COMPRESSED_RGBA;
                align_unpack = 4;
                break;
            
            case GL_RGB:
                internal = GL_COMPRESSED_RGB;
                align_unpack = 1;
                break;
        }

        //debug writeln("Format: ", _name[format], " internal: ", _name[internal]);

        //TODO("Alpha maps not working");

        checkgl!glGenTextures(1, &ID);
        checkgl!glBindTexture(GL_TEXTURE_2D, ID);

        width = w;
        height = h;

        glPixelStorei(GL_UNPACK_ALIGNMENT, align_unpack);
        //glPixelStorei(GL_PACK_ALIGNMENT, 1);

        checkgl!glTexImage2D(GL_TEXTURE_2D,
            0,                  // Mipmap level
            format,             // Internal format
            w, h,
            0,                  // Border
            format,             // Format of data
            data_width,         // Data width
            buffer              // Actual data
        );

        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

        //checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        //checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

        //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);

        checkgl!glBindTexture(GL_TEXTURE_2D, 0);
    }

    //-------------------------------------------------------------------------

    ~this()
    {
        glDeleteTextures(1, &ID);
    }

    //-------------------------------------------------------------------------
    // SDL surface to texture
    //-------------------------------------------------------------------------

    this(SDL_Surface *surface)
    {
        this(
            surface.w, surface.h,
            surface.pixels,
            _GLformat(surface)
        );
    }

    //-------------------------------------------------------------------------
    // Loading texture from blob file
    //-------------------------------------------------------------------------

    this(string filename)
    {
        SDL_Surface* img = blob.loadimage(filename);
        this(img);
        //debug writeln("Texture.: ", filename, ": ", img.w, " x ", img.h);
        //debug writeln("- Pixels: ", img.pixels[0 .. 5]);

        SDL_FreeSurface(img);
    }

    //-------------------------------------------------------------------------
    // Creating single pixel "dummy" textures
    //-------------------------------------------------------------------------

    this(vec4 color)
    {
        ubyte[] buffer = [
            cast(ubyte)(color.r*255),
            cast(ubyte)(color.g*255),
            cast(ubyte)(color.b*255),
            cast(ubyte)(color.a*255)
        ];
        this(1, 1, buffer.ptr, GL_RGBA);
    }
}

