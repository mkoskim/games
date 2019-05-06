//*****************************************************************************
//
// Sketching plugging LUA to game engine.
//
//*****************************************************************************

import engine;
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
    foreach(arg; args) Log << format("    %s", to!string(arg));
}

void printout(Variant arg)
{
    printout([arg]);
}

void printout(string prefix, Variant[] args)
{
    Log << prefix;
    printout(args);
}

void printout(string prefix, Variant arg)
{
    printout(prefix, [arg]);
}

//lua_CFunction luaGimme
extern(C) nothrow int bounceback(lua_State *L)
{
    try
    {
        auto lua = Lua.attach(L);

        auto args = lua.args();

        Log << format("bounceback(): %s", to!string(args));
        
        return lua.result("called");
        //return lua.result(args);
        
    } catch(Throwable)
    {
    }
    
    return 0;
}

luaL_Reg[] bouncelib = [
    luaL_Reg("bounceback", &bounceback),
    luaL_Reg(null, null)
];

//-----------------------------------------------------------------------------
// Creating interface for LUA to access D functions
//-----------------------------------------------------------------------------

void test()
{
    auto lua = new Lua();
    scope(exit) { lua.destroy(); }

    vfs.fallback = true;

    //-------------------------------------------------------------------------
    
    static if(0) printout("main.lua returns:", lua.load("data/main.lua"));

    //-------------------------------------------------------------------------
    
    printout("test.lua returns:", lua.load("data/test.lua"));

    //-------------------------------------------------------------------------
    // Call lua function:
    //-------------------------------------------------------------------------
    
    printout("show:", lua["show"].call(&bounceback, 2, 3));
    printout("show:", lua["show"].call(1, 2, 3));
    printout("show:", lua["show"].call(4, 5, 6));
    printout("show:", lua["show"].call("A", 8, "B"));

    //-------------------------------------------------------------------------
    // Check multi return
    //-------------------------------------------------------------------------

    printout("multiret:", lua["multiret"].call());
    
    //-------------------------------------------------------------------------
    // Inspect table created in lua file
    //-------------------------------------------------------------------------

    lua["mytable"]["c"][1].set("c");
    printout("mytable['a'] = ", lua["mytable"]["a"].get());
    printout("mytable['c'][1] = ", lua["mytable"]["c"][1].get());

    printout("mytable[1]   = ", lua["mytable"][1].get());
    printout("mytable['1'] = ", lua["mytable"]["1"].get());

    //-------------------------------------------------------------------------
    // Inspect table created in lua file
    //-------------------------------------------------------------------------
    
    printout("Keys:", lua["mytable"].keys());

    //-------------------------------------------------------------------------
    // Inspect global symbols
    //-------------------------------------------------------------------------
    
    printout("_G:", lua["_G"].keys());

    //-------------------------------------------------------------------------
    // Call function via table: string.format
    //-------------------------------------------------------------------------
    
    printout("string.format:", lua["string"]["format"].call("Test %d", 12));

    //-------------------------------------------------------------------------
    // Register function and call it
    //-------------------------------------------------------------------------

    lua["gbounce"].set(&bounceback);
    printout("bounce (global):", lua["gbounce"].call(1, 2));

    lua["mytable"]["bounce"].set(&bounceback);
    printout("bounce (mytable):", lua["mytable"]["bounce"].call(1, 2));

    lua["bounce"].set(bouncelib);
    printout("bounce:", lua["bounce"]["bounceback"].call("A", 1, 2, "C"));
    printout("bounce:", lua["callbounce"].call());

    //-------------------------------------------------------------------------
    // Invalid uses of indexing
    //-------------------------------------------------------------------------

    lua["show"];  // Fixed: Leaves carbage to stack

    auto luashow = lua["show"];
    luashow.call(1);
    auto multiret = lua["multiret"];
    printout("luashow", luashow.call(1));
    //luashow.call(2);

static if(0) {

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
}
    Log << "Done.";
}

void main()
{
    test();

    // It might be good idea to run GC after assets are loaded (I
    // think it will produce lots of memory allocations).

    Track.GC.run();
    debug Track.report();

    Log << "All done.";
}

