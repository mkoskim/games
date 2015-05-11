//*****************************************************************************
//
// Misc. loaders
//
//*****************************************************************************

module engine.blob.misc;

//-----------------------------------------------------------------------------
// SDL (images and fonts)
//-----------------------------------------------------------------------------

import std.file: FileException;
import std.string: format;
import std.conv: to;

import engine.blob.extract;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import derelict.sdl2.image;

//-----------------------------------------------------------------------------

SDL_Surface* loadimage(string filename)
{
    auto buffer = extract(filename);
    auto img = IMG_Load_RW(SDL_RWFromConstMem(buffer.ptr, cast(int)buffer.length), true);

    if(!img) throw new FileException(
        filename,
        format("SDL:IMG_Load_RW: %s",to!string(SDL_GetError()))
    );

    return img;
}

//-----------------------------------------------------------------------------

TTF_Font* loadfont(string filename, int ptsize)
{
    auto buffer = extract(filename);
    auto font = TTF_OpenFontRW(
        SDL_RWFromConstMem(buffer.ptr, cast(int)buffer.length),
        true, 
        ptsize
    );

    if(!font) throw new FileException(
        filename,
        format("SDL:TTF_OpenFontRW: %s",to!string(SDL_GetError()))
    );

    return font;
}

