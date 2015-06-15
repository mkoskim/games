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
        SDL_DestroyRenderer(renderer);
        SDL_FreeSurface(surface);
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
    // Spritesheet splitter
    //-------------------------------------------------------------------------

    static Bitmap[][] splitSheet(
        Bitmap sheet,
        int texw, int texh,
        int padx = 0, int pady = 0
    )
    {
        //debug writeln("Texture.: ", filename, ": ", img.w, " x ", img.h);
        //debug writeln("- Pixels: ", img.pixels[0 .. 5]);

        int cols = sheet.surface.w / (texw+padx);
        int rows = sheet.surface.h / (texh+pady);

        Bitmap[][] grid = new Bitmap[][](rows, cols);

        /*
        SDL_Surface *temp = SDL_CreateRGBSurface(0, texw, texh, 32, 0, 0, 0, 0);
        SDL_Surface *sprite = SDL_ConvertSurface(temp, sheet.format, 0);
        SDL_FreeSurface(temp);
        */

        SDL_Rect srcrect = {x: 0, y: 0, w: texw, h: texh};
        SDL_Rect dstrect = {x: 0, y: 0, w: texw, h: texh};

        foreach(y; 0 .. rows) foreach(x; 0 .. cols)
        {
            auto sprite = new Bitmap(texw, texh);

            srcrect.y = y*(texh + pady);
            srcrect.x = x*(texw + padx);

            //SDL_FillRect(sprite.surface, &dstrect, 0);
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
        int texw, int texh,
        int padx = 0, int pady = 0
    )
    {
        return splitSheet(
            blob.loadimage(filename),
            texw, texh,
            padx, pady
        );
    }

    static Bitmap[][] splitSheet(
        SDL_Surface *sheet,
        int texw, int texh,
        int padx = 0, int pady = 0
    )
    {
        return splitSheet(
            new Bitmap(sheet),
            texw, texh,
            padx, pady
        );
    }

    static Bitmap[][] splitSheet(
        string[] grid, vec4[char] colorchart,
        int texw, int texh,
        int padx = 0, int pady = 0
    )
    {
        return splitSheet(
            new Bitmap(grid, colorchart),
            texw, texh,
            padx, pady
        );
    }

    //-------------------------------------------------------------------------
    // Simple bitmaps from strings
    //-------------------------------------------------------------------------    
}

