//*****************************************************************************
//
// Game engine main file
//
//*****************************************************************************

module engine;

//-----------------------------------------------------------------------------
// Engine core
//-----------------------------------------------------------------------------

public import game = engine.game;
public import render = engine.render;
public import blob = engine.blob;

//-----------------------------------------------------------------------------
// Some helpers
//-----------------------------------------------------------------------------

public import engine.ext;

//-----------------------------------------------------------------------------
// Default libraries (for types and functions to work with them)
//-----------------------------------------------------------------------------

public import derelict.sdl2.sdl;
public import derelict.sdl2.image;
public import derelict.sdl2.ttf;
public import derelict.opengl3.gl3;
public import gl3n.linalg;

pragma(lib, "dl");

//-----------------------------------------------------------------------------

static this()
{
    DerelictSDL2.load();
    DerelictSDL2Image.load();
    DerelictSDL2ttf.load();
    DerelictGL3.load();

    //-------------------------------------------------------------------------

    SDL_Init(0);

    int img_formats = IMG_INIT_PNG;
    if(IMG_Init(img_formats) != img_formats) {
        throw new Exception(format("IMG_Init: %s", to!string(IMG_GetError())));
    }

    //-------------------------------------------------------------------------

    TTF_Init();
}

static ~this()
{
    TTF_Quit();
    IMG_Quit();
    SDL_Quit();
}

