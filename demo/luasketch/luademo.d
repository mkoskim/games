//*****************************************************************************
//
// Sketching plugging LUA to game engine.
//
//*****************************************************************************

import engine;

import std.stdio;
import std.conv: to;

import engine.util.lua: Lua;

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

import std.variant: Variant;

void printout(Variant[] args)
{
    foreach(arg; args) writeln("    ", arg.to!string);
}

void printout(Variant arg)
{
    printout([arg]);
}

void printout(string prefix, Variant[] args)
{
    writeln(prefix);
    printout(args);
}

void printout(string prefix, Variant args)
{
    writeln(prefix);
    printout(args);
}

static if(0)
{
private extern(C) int luaGimme(lua_State *L) nothrow
{
    try {
        auto lua = Lua.attach(L);
        // Get args
        printout("Lua: ", lua.pop(lua.top()));
        // store results
        // return number of results
    } catch(Throwable) {
    }
    
    return 0;
}
}

//-----------------------------------------------------------------------------
// Creating interface for LUA to access D functions
//-----------------------------------------------------------------------------

void test()
{
    auto lua = new Lua();
    scope(exit) { lua.destroy(); }

    //-------------------------------------------------------------------------
    
    static if(0) printout("main.lua returns:", lua.load("data/main.lua"));

    //-------------------------------------------------------------------------
    
    printout("test.lua returns:", lua.load("data/test.lua"));

    //-------------------------------------------------------------------------
    // Call lua function:
    //-------------------------------------------------------------------------
    
    printout("show:", lua["show"].call(1, 2, 3));
    printout("show:", lua["show"].call(4, 5, 6));
    printout("show:", lua["show"].call("A", 8, "B"));

    //-------------------------------------------------------------------------
    // Check multi return
    //-------------------------------------------------------------------------

    printout("multiret:", lua["multiret"].call());

    //-------------------------------------------------------------------------
    // Call function via table: string.format
    //-------------------------------------------------------------------------
    
    printout("string.format:", lua["string", "format"].call("Test %d", 12));

    //-------------------------------------------------------------------------
    // Inspect table created in lua file
    //-------------------------------------------------------------------------

    printout("mytable['a']:", lua["mytable", "a"].get());
    printout("mytable['c'][1]:", lua["mytable", "c", 1].get());

static if(0) {

    //-------------------------------------------------------------------------
    // Inspect table created in lua file
    //-------------------------------------------------------------------------
    
    printout("Keys:", lua["mytable"].keys());

    //-------------------------------------------------------------------------
    // Inspect global symbols
    //-------------------------------------------------------------------------
    
    printout("_G:", lua["_G"].keys());

    //-------------------------------------------------------------------------
    // Get reference to string, and use it to call format
    //-------------------------------------------------------------------------
    
    auto stringlib = lua["string"];
    printout(
        "string.format:",
        stringlib["format"]("Test %d", 13)
    );

//*
    //-------------------------------------------------------------------------
    // howdy() returns table, check it
    //-------------------------------------------------------------------------

    auto howdy = lua["howdy"];
    writeln("howdy = ", howdy.type);
    
    auto ret = howdy();
    
    printout("howdy():", ret);
    ret[0].dumptable();
/**/
    //-------------------------------------------------------------------------
    // Load another file and check what main returns
    //-------------------------------------------------------------------------

}
    writeln("Done.");
}

void main()
{
    test();

    // It might be good idea to run GC after assets are loaded (I
    // think it will produce lots of memory allocations).

    debug Track.report();

    writeln("All done.");
}

