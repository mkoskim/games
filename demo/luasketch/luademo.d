//*****************************************************************************
//
// Sketching plugging LUA to game engine.
//
//*****************************************************************************

import engine;
debug import engine.game: Track;

import std.stdio;
import std.conv: to;

import engine.asset.lua: Lua;
/*
    LuaType,
    LuaObject, LuaNone, LuaNil,
    LuaBool, LuaNumber, LuaString,
    LuaReference,
    LuaTable, LuaFunction;
*/

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

void printout(Lua.Value[] args)
{
    foreach(arg; args) writeln("    ", arg.to!string);
}

void printout(Lua.Value arg)
{
    printout([arg]);
}

void printout(string prefix, Lua.Value[] args)
{
    writeln(prefix);
    printout(args);
}

private extern(C) int luaGimme(lua_State *L) nothrow
{
    try {
        auto lua  = new Lua(L);
        printout("Lua: ", lua.pop(lua.top()));
    } catch(Throwable) {
    }
    
    return 0;
}

private const luaL_Reg[] globals = [
    //{ "print", &luaIoWrite },
    { "gimme", &luaGimme },
    //{ "crash", &luaCrash },
    { null, null },
];

//-----------------------------------------------------------------------------
// Creating interface for LUA to access D functions
//-----------------------------------------------------------------------------

void test()
{
    //-------------------------------------------------------------------------

    auto lua = new Lua();

    luaL_register(lua.L, "_G", globals.ptr);
    lua.top = 0;

    //-------------------------------------------------------------------------
    
    lua.load("data/test.lua");

    //-------------------------------------------------------------------------
    // Inspect global symbols
    //-------------------------------------------------------------------------
    
    printout("_G:", lua["_G"].keys());

    //-------------------------------------------------------------------------
    // Inspect table created in lua file
    //-------------------------------------------------------------------------
    
    printout("Keys:", lua["mytable"].keys());

    //-------------------------------------------------------------------------
    // Call library function: string.format
    //-------------------------------------------------------------------------
    
    printout(
        "string.format:",
        lua["string", "format"]("Test %d", 12)
    );

    //-------------------------------------------------------------------------
    // Get reference to string, and use it to call format
    //-------------------------------------------------------------------------
    
    auto stringlib = lua["string"];
    printout(
        "string.format:",
        stringlib["format"]("Test %d", 13)
    );

    //-------------------------------------------------------------------------
    // Check multi return
    //-------------------------------------------------------------------------

    printout("multiret:", lua["multiret"]());

//*
    //-------------------------------------------------------------------------
    // howdy() returns table, check it
    //-------------------------------------------------------------------------

    auto howdy = lua["howdy"];
    writeln("howdy = ", howdy.type);
    
    auto ret = howdy();
    
    printout("howdy():", ret);
    ret[0].dumptable();

    //-------------------------------------------------------------------------
    // Load another file and check what main returns
    //-------------------------------------------------------------------------

    printout("main returns:", lua.load("data/main.lua"));

/**/
    debug Track.report();
    writeln("Done.");
}

void main()
{
    test();

    // It might be good idea to run GC after assets are loaded (I
    // think it will produce lots of memory allocations).

    engine.game.rungc();
    debug Track.report();

    writeln("All done.");
}

