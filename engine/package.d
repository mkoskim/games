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

    import engine.util.logger: Log, Watch;
    debug import engine.util.track: Track;
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

//-----------------------------------------------------------------------------

import derelict.sdl2.image;
import derelict.sdl2.ttf;
import engine.util;

//-----------------------------------------------------------------------------

version(linux) pragma(lib, "dl");

//-----------------------------------------------------------------------------

static this()
{
    Log << "Loading libraries...";
    
    //-------------------------------------------------------------------------
    // Load OpenGL
    //-------------------------------------------------------------------------

    Log << "Loading: OpenGL...";
    DerelictGL3.load();

    //-------------------------------------------------------------------------
    // Load & Initialize SDL2
    //-------------------------------------------------------------------------

    Log << "Loading: SDL2...";
    DerelictSDL2.load(SharedLibVersion(2, 0, 2));
    SDL_Init(0);

    //-------------------------------------------------------------------------
    // Load & initialize SDL2Image (problems loading PNG.DLL in Windows)
    //-------------------------------------------------------------------------

    Log << "Loading: SDL2Image...";
    DerelictSDL2Image.load();

    version(Windows)
    {
        int img_formats = IMG_INIT_JPG;
    } else {
        int img_formats = IMG_INIT_PNG | IMG_INIT_JPG;
    }

    if(IMG_Init(img_formats) != img_formats) {
        throw new Exception(format("IMG_Init: %s", to!string(IMG_GetError())));
    }

    //-------------------------------------------------------------------------
    // Load & Init SDL TTF (does not yet work in Windows build)
    //-------------------------------------------------------------------------

    version(Windows)
    {
    } else {
        Log << "Loading: SDL2TTF...";
        DerelictSDL2ttf.load();
        TTF_Init();
    }

    //-------------------------------------------------------------------------
    // Load ASSIMP
    //-------------------------------------------------------------------------

    Log << "Loading: ASSIMP...";
    DerelictASSIMP3.load();

    //-------------------------------------------------------------------------
    // Linux Mint - and probably all Ubuntu variants - have obscure lua
    // library name
    //-------------------------------------------------------------------------

    Log << "Loading: Lua...";
    version(linux)
    {
        DerelictLua.load("liblua5.3.so");        
    } else {
        DerelictLua.load();
    }

    //-------------------------------------------------------------------------

    Log << "Libraries loaded.";
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

