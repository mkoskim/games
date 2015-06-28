//*****************************************************************************
//
// CPU side bitmap manipulation
//
//*****************************************************************************

module engine.ext.bitmap;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;
import engine.ext.util;
import blob = engine.blob;

//-----------------------------------------------------------------------------

class Bitmap
{
    SDL_Surface* surface;
    SDL_Renderer* renderer;

    //-------------------------------------------------------------------------

    this(SDL_Surface* s)
    {
        Track.add(this);
        surface = s;
        renderer = SDL_CreateSoftwareRenderer(surface);
        if(!renderer) throw new Exception(
            format("CreateSoftwareRenderer failed: %s", SDL_GetError())
        );
    }

    this(int width, int height)
    {
        SDL_Surface* s = SDL_CreateRGBSurface(
            0,
            width,height,
            32,
            0x000000ff,
            0x0000ff00,
            0x00ff0000,
            0xff000000
        );
        if(!s) throw new Exception(
            format("CreateRGBSurface failed: %s", SDL_GetError())
        );
        this(s);
    }

    this(string filename)
    {
        this(blob.loadimage(filename));
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

    ~this()
    {
        Track.remove(this);
        if(SDL_up) {
            SDL_DestroyRenderer(renderer);
            SDL_FreeSurface(surface);
        }
    }

    //-------------------------------------------------------------------------

    int width()  { return surface.w; }
    int height() { return surface.h; }

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

        /*
        SDL_FreeSurface(sheet);
        SDL_FreeSurface(sprite);
        */

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

    /*
    static Bitmap[][] splitSheet(
        SDL_Surface *sheet,
        vec2i srcsize,
        vec2i dstsize,
        vec2i top = vec2i(0, 0),
        vec2i bottom = vec2i(0, 0)        
    )
    {
        return splitSheet(
            new Bitmap(sheet),
            srcsize, dstsize,
            top, bottom
        );
    }
    */

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

