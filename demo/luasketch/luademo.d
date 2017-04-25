//*****************************************************************************
//
// Sketching plugging LUA to game engine.
//
//*****************************************************************************

import engine;

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
//          Cubemap cubemap = Cubemap("img1", "img2", ...);
//          return SkyBox(cubemap);
//
//*****************************************************************************

import std.stdio;
import std.string: toStringz;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

class Lua
{
    lua_State *L;
    
    //-------------------------------------------------------------------------
    
    this()
    {
        L = luaL_newstate();
        luaL_openlibs(L);
    }

    ~this() { lua_close(L); }

    //-------------------------------------------------------------------------
            
    //-------------------------------------------------------------------------
    
    void eval(string s)
    {
        if(luaL_loadstring(L, toStringz(s)) != 0)
        {
            lua_error(L);
        }
    }
    
    void load(string s)
    {
        eval(engine.asset.blob.text(s));
    }

    //-------------------------------------------------------------------------
    
}


//-----------------------------------------------------------------------------
// Creating interface for LUA to access D functions
//-----------------------------------------------------------------------------

import derelict.lua.lua;

void main()
{
    auto lua = new Lua;
    lua.load("data/test.lua");

    lua_pcall(lua.L, 0, LUA_MULTRET, 0);
    
    writeln("Done.");
}

