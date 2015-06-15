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
import engine.ext.bitmap;
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
    // Creating texture from pixel data buffer
    //-------------------------------------------------------------------------

    this(uint w, uint h, void* buffer, GLenum format, GLenum data_width = GL_UNSIGNED_BYTE)
    {
        debug const string[GLenum] _name = [
            GL_BGRA: "GL_BGRA",
            GL_RGBA: "GL_RGBA",
            GL_BGR: "GL_BGR",
            GL_RGB: "GL_RGB",
            
            GL_RGB8: "GL_RGB8",

            GL_COMPRESSED_RGB: "GL_COMPRESSED_RGB",
            GL_COMPRESSED_RGBA: "GL_COMPRESSED_RGBA",
        ];
        
        checkgl!glGenTextures(1, &ID);

        width = w;
        height = h;

        final switch(format)
        {
            // TODO: BGR(A) formats seem not to work
            case GL_BGRA: format = GL_RGBA; goto case GL_RGBA;
            case GL_BGR: format = GL_RGB; goto case GL_RGB;
                
            case GL_RGB8: format = GL_RGB; goto case GL_RGB;
            
            case GL_RGBA:
                unpack_align(4);
                break;
            
            case GL_RGB: switch(data_width)
            {
                case GL_UNSIGNED_BYTE: unpack_align(1); break;
                default: unpack_align(4); break;
            } break;
        }

        //debug writeln("Format: ", _name[format], " internal: ", _name[internal]);

        //TODO("Alpha maps not working");

        bind();
        checkgl!glTexImage2D(GL_TEXTURE_2D,
            0,                  // Mipmap level
            format,             // Internal format
            w, h,
            0,                  // Border
            format,             // Format of data
            data_width,         // Data width
            buffer              // Actual data
        );
        unbind();

        filtering(GL_LINEAR, GL_LINEAR);
        wrapping(GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE);
        //filtering(GL_NEAREST, GL_NEAREST);
        //filtering(GL_LINEAR_MIPMAP_NEAREST, GL_LINEAR);
    }

    //-------------------------------------------------------------------------

    void bind()   { checkgl!glBindTexture(GL_TEXTURE_2D, ID); }
    void unbind() { checkgl!glBindTexture(GL_TEXTURE_2D, 0); }
    
    void filtering(GLenum min, GLenum mag)
    {
        bind();
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, mag);
        checkgl!glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, min);
        unbind();
    }

    void unpack_align(GLint alignment)
    {
        bind();
        checkgl!glPixelStorei(GL_UNPACK_ALIGNMENT, alignment);
        unbind();
    }

    void wrapping(GLenum s, GLenum t)
    {
        bind();
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, s);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, t);
        unbind();
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

    this(Bitmap bitmap) { this(bitmap.surface); }

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
        this(1, 1, cast(void*)color.value_ptr, GL_RGBA, GL_FLOAT);
    }

    //-------------------------------------------------------------------------
    // Texture sheets
    //-------------------------------------------------------------------------

    static Texture[][] upload(Bitmap[][] bitmaps)
    {
        Texture[][] grid;
        
        foreach(row; bitmaps) {
            Texture[] line;
            foreach(bitmap; row) {
                line ~= new Texture(bitmap);
            }
            grid ~= line;
        }
        return grid;
    }
}

