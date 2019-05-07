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
// Default libraries (for types and functions to work with them)
//-----------------------------------------------------------------------------

public {
    import derelict.sdl2.sdl;
    import derelict.opengl.gl;
    import derelict.assimp3.assimp;
    import derelict.lua.lua;
    import gl3n.linalg;
    import gl3n.aabb;    
}

//-----------------------------------------------------------------------------
// Some helpers
//-----------------------------------------------------------------------------

public {
    import engine.math;
    import engine.ext;
    import engine.util;
    import std.exception: enforce;
    import engine.util.logger: Log, Watch;
    debug import engine.util.track: Track;
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
    auto log = Log["Startup"];
    
    "Loading libraries..." >> log;
    
    //-------------------------------------------------------------------------
    // Load OpenGL
    //-------------------------------------------------------------------------

    "Loading: OpenGL..." >> log;
    DerelictGL3.load();

    //-------------------------------------------------------------------------
    // Load & Initialize SDL2
    //-------------------------------------------------------------------------

    "Loading: SDL2..." >> log;
    DerelictSDL2.load(SharedLibVersion(2, 0, 4));
    SDL_Init(0);

    //-------------------------------------------------------------------------
    // Load & initialize SDL2Image (problems loading PNG.DLL in Windows)
    //-------------------------------------------------------------------------

    "Loading: SDL2Image..." >> log;
    DerelictSDL2Image.load();

    int img_formats = IMG_INIT_JPG | IMG_INIT_PNG;

    if(IMG_Init(img_formats) != img_formats) {
        throw new Exception(format("IMG_Init: %s", to!string(IMG_GetError())));
    }

    //-------------------------------------------------------------------------
    // Load & Init SDL TTF (does not yet work in Windows build)
    //-------------------------------------------------------------------------

    "Loading: SDL2TTF..." >> log;
    DerelictSDL2ttf.load();
    TTF_Init();

    //-------------------------------------------------------------------------
    // Load ASSIMP
    //-------------------------------------------------------------------------

    "Loading: ASSIMP..." >> log;
    DerelictASSIMP3.load();

    //-------------------------------------------------------------------------
    // Linux Mint - and probably all Ubuntu variants - have obscure lua
    // library name
    //-------------------------------------------------------------------------

    "Loading: Lua..." >> log;
    version(linux)
    {
        DerelictLua.load("liblua5.3.so");        
    } else {
        DerelictLua.load();
    }

    //-------------------------------------------------------------------------

    "Libraries loaded." >> log;
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

