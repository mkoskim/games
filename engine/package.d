//*****************************************************************************
//
// Game engine main file
//
//*****************************************************************************

module engine;

//-----------------------------------------------------------------------------
// Engine core
//-----------------------------------------------------------------------------

public {
    import game = engine.game;
    import asset = engine.asset;
    import gpu = engine.gpu;
}

//-----------------------------------------------------------------------------
// Some helpers
//-----------------------------------------------------------------------------

public import engine.math;
public import engine.ext;

//-----------------------------------------------------------------------------
// Default libraries (for types and functions to work with them)
//-----------------------------------------------------------------------------

public {
    import derelict.sdl2.sdl;
    import derelict.opengl.gl;
    import derelict.assimp3.assimp;
    import derelict.lua.lua;
    import gl3n.linalg;
    
    import std.exception: enforce;
    import std.stdio: writeln, writefln;
}

pragma(lib, "dl");

//-----------------------------------------------------------------------------

import derelict.sdl2.image;
import derelict.sdl2.ttf;
import engine.util;

//-----------------------------------------------------------------------------

static this()
{
    DerelictSDL2.load(SharedLibVersion(2, 0, 2));
    DerelictSDL2Image.load();
    DerelictSDL2ttf.load();
    DerelictGL3.load();
    DerelictASSIMP3.load();
    DerelictLua.load("liblua5.3.so");

    //-------------------------------------------------------------------------

    SDL_Init(0);

    int img_formats = IMG_INIT_PNG | IMG_INIT_JPG;
    if(IMG_Init(img_formats) != img_formats) {
        throw new Exception(format("IMG_Init: %s", to!string(IMG_GetError())));
    }

    //-------------------------------------------------------------------------

    TTF_Init();
}

static ~this()
{
    /**************************************************************************
    **
    ** NOTE: Shutting down SDL at exit may sound a good idea. BUT there is
    ** no guarantee in what order DMD calls destructors, causing attempts to
    ** destroy SDL resources to produce random segfaults, glibc memory
    ** allocation errors etc.
    **
    ** So, better keep the interface up to the bitter end.
    **
    **************************************************************************/

    // TTF_Quit();
    // IMG_Quit();
    // SDL_Quit();
}

