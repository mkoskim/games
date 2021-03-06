//*****************************************************************************
//
// CPU side bitmaps
//
//*****************************************************************************

module engine.asset.bitmap;

//-----------------------------------------------------------------------------

import engine.asset.util;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.file: FileException;
import std.string: format;
import std.conv: to;

//-----------------------------------------------------------------------------

class Bitmap
{
    SDL_Surface* surface = null;
    private SDL_Renderer* _renderer = null;

    //-------------------------------------------------------------------------

    this(SDL_Surface* s) in { assert(s); } body
    {
        debug Track.add(this);
        surface = s;
    }

    ~this()
    {
        debug Track.remove(this);
        if(_renderer) SDL_DestroyRenderer(_renderer);
        SDL_FreeSurface(surface);
    }

    //-------------------------------------------------------------------------
    // Creating empty bitmap: We could assume here that forthcoming calls
    // are going to draw something on bitmap, so basically - basically -
    // we could create renderer already.
    //-------------------------------------------------------------------------

    this(int width, int height)
    {
        SDL_Surface* s = SDL_CreateRGBSurface(
            0,
            width, height,
            32,
            0x000000ff,
            0x0000ff00,
            0x00ff0000,
            0xff000000
        );

        ERRORIF(!s, to!string(SDL_GetError()));
        this(s);
    }

    //-------------------------------------------------------------------------

    private static SDL_Surface* loadimage(string filename)
    {
        auto buffer = vfs.extract(filename);
        auto img = IMG_Load_RW(SDL_RWFromConstMem(buffer.ptr, cast(int)buffer.length), true);

        if(!img) throw new FileException(
            filename,
            format("SDL:IMG_Load_RW: %s",to!string(SDL_GetError()))
        );

        return img;
    }

    this(string filename)
    {
        this(loadimage(filename));
    }

    this(string[] grid, vec4[char] colorchart)
    {
        this(
            cast(int)grid[0].length,
            cast(int)grid.length
        );

        foreach(y; 0 .. height) {
            foreach(x; 0 .. width) {
                putpixel(x, y, colorchart[grid[y][x]]);
            }
        }
    }

    //-------------------------------------------------------------------------

    int width()  { return surface.w; }
    int height() { return surface.h; }

    //*************************************************************************
    //
    // CPU side bitmap manipulation
    //
    //*************************************************************************

    //-------------------------------------------------------------------------
    // Possibly useful operations:
    //
    // 1) Scaling, definitely!
    // 2) Adding and removing alpha layer, or use another bitmap as alpha
    //    layer (and extracting alpha to bitmap)
    // 3) Related to that, red <-> alpha conversions for texture upload
    // 4) "Stamping", combining bitmaps (e.g. stonewall with graffiti,
    //    face with skin color) at load time (we most probably has this kind
    //    of feature at shader side, too)
    //
    //-------------------------------------------------------------------------

    SDL_Renderer* renderer() {
        if(!_renderer) _renderer = SDL_CreateSoftwareRenderer(surface);
        ERRORIF(!_renderer, to!string(SDL_GetError()));
        return _renderer;
    }

    //-------------------------------------------------------------------------

    void putpixel(int x, int y, vec4 color)
    {
        SDL_SetRenderDrawColor(renderer, 
            cast(ubyte)(color.r*255),
            cast(ubyte)(color.g*255),
            cast(ubyte)(color.b*255),
            cast(ubyte)(color.a*255)
        );
        SDL_RenderDrawPoint(renderer, x, y);
    }

    //-------------------------------------------------------------------------
    // Spritesheet splitter. TODO: Bitmap scaling does not work
    //-------------------------------------------------------------------------

    static Bitmap[][] splitSheet(
        Bitmap sheet,
        vec2i size,
        vec2i top = vec2i(0, 0),
        vec2i bottom = vec2i(0, 0),
    )
    {
        //debug writeln("Texture.: ", filename, ": ", img.w, " x ", img.h);
        //debug writeln("- Pixels: ", img.pixels[0 .. 5]);

        int cols = sheet.surface.w / (size.x + top.x + bottom.x);
        int rows = sheet.surface.h / (size.y + top.y + bottom.y); 

        Bitmap[][] grid = new Bitmap[][](rows, cols);

        SDL_Rect srcrect = {x: 0, y: 0, w: size.x, h: size.y};
        SDL_Rect dstrect = {x: 0, y: 0, w: size.x, h: size.y};

        foreach(y; 0 .. rows) foreach(x; 0 .. cols)
        {
            auto sprite = new Bitmap(size.x, size.y);

            srcrect.x = top.x + x*(size.x + top.x + bottom.x);
            srcrect.y = top.y + y*(size.y + top.y + bottom.y);

            SDL_BlitSurface(
                sheet.surface, &srcrect,
                sprite.surface, &dstrect
            );
            
            grid[y][x] = sprite;
            
            //SDL_SaveBMP(sprite, "test.bmp");
            //throw new Exception();
        }

        return grid;
    }

    static Bitmap[][] splitSheet(
        string filename,
        vec2i size,
        vec2i top = vec2i(0, 0),
        vec2i bottom = vec2i(0, 0)
    )
    {
        return splitSheet(
            new Bitmap(filename),
            size,
            top, bottom
        );
    }

    static Bitmap[][] splitSheet(
        string[] grid, vec4[char] colorchart,
        vec2i size,
        vec2i top = vec2i(0, 0),
        vec2i bottom = vec2i(0, 0)
    )
    {
        return splitSheet(
            new Bitmap(grid, colorchart),
            size,
            top, bottom
        );
    }
}

