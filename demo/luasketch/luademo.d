//*****************************************************************************
//
// Sketching plugging LUA to game engine.
//
//*****************************************************************************

import engine;

import std.stdio;

//*****************************************************************************
//
// How I want it to work (sketch):
//
//      main.d:
//
//          auto skybox = SkyBox("path/to/skybox.lua");
//
//      skybox1.lua:
//
//          cubemap = Cubemap("img1", "img2", ...);
//          return SkyBox(cubemap);
//
//*****************************************************************************


//-----------------------------------------------------------------------------
// Creating interface for LUA to access D functions
//-----------------------------------------------------------------------------

void main()
{
    auto lua = new engine.asset.Lua("data/test.lua");

    lua.call("howdy");
    writeln(
        "show() returns: ",
        lua.call("show", 1.2)
    );

    writeln(
        "main.lua returns: ",
        lua.load("data/main.lua")
    );    

    writeln("Done.");
}

