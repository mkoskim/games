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

private extern(C) int luaIoWrite(lua_State *L) nothrow
{
    try {
        auto lua = new engine.asset.Lua(L);
        write("Lua: ");
        for(int i = 1; i <= lua_gettop(L); i++) write(lua.fetch(i), " ");
        writeln();
    } catch(Throwable) {
    }
    
    return 0;
}

private const luaL_Reg[] globals = [
    { "print", &luaIoWrite },
    { null, null },
];

//-----------------------------------------------------------------------------
// Creating interface for LUA to access D functions
//-----------------------------------------------------------------------------

void main()
{
    auto lua = new engine.asset.Lua();

    luaL_register(lua.L, "_G", globals.ptr);
    lua_settop(lua.L, 0);
    
    lua.load("data/test.lua");
    lua.call("howdy");
    writeln(
        "show() returns: ",
        lua.call("show", 1.2, 3.4, 5.6)
    );

    writeln(
        "main.lua returns: ",
        lua.load("data/main.lua")
    );    

    writeln("Done.");
}

