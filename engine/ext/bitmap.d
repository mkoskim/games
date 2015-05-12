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
        string filename,
        int texw, int texh,
        int padx = 0, int pady = 0
    )
    {
        SDL_Surface* sheet = blob.loadimage(filename);
        //debug writeln("Texture.: ", filename, ": ", img.w, " x ", img.h);
        //debug writeln("- Pixels: ", img.pixels[0 .. 5]);

        int cols = sheet.w / (texw+padx);
        int rows = sheet.h / (texh+pady);

        Bitmap[][] grid = new Bitmap[][](rows, cols);

        SDL_Surface *temp = SDL_CreateRGBSurface(0, texw, texh, 32, 0, 0, 0, 0);
        SDL_Surface *sprite = SDL_ConvertSurface(temp, sheet.format, 0);
        SDL_FreeSurface(temp);

        SDL_Rect srcrect = {x: 0, y: 0, w: texw, h: texh};
        SDL_Rect dstrect = {x: 0, y: 0, w: texw, h: texh};

        foreach(y; 0 .. rows) foreach(x; 0 .. cols)
        {
            srcrect.y = y*(texh + pady);
            srcrect.x = x*(texw + padx);

            SDL_FillRect(sprite, &dstrect, 0);
            SDL_BlitSurface(
                sheet, &srcrect,
                sprite, &dstrect
            );

            //SDL_SaveBMP(sprite, "test.bmp");
            //throw new Exception();

            grid[y][x] = new Bitmap(sprite);
        }

        SDL_FreeSurface(sheet);
        SDL_FreeSurface(sprite);

        return grid;
    }
}

