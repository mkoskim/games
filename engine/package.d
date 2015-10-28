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
    import render = engine.render;
    import gpu = engine.render.gpu;
    import scene3d = engine.render.scene3d;
    import postprocess = engine.render.postprocess;
    import blob = engine.blob;
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
    import derelict.opengl3.gl3;
    import derelict.assimp3.assimp;
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
    debug Track.add(__FILE__);

    DerelictSDL2.load();
    DerelictSDL2Image.load();
    DerelictSDL2ttf.load();
    DerelictGL3.load();
    DerelictASSIMP3.load();

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
    debug Track.remove(__FILE__);

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

