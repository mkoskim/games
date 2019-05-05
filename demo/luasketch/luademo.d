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

private extern(C) nothrow int luaGimme(lua_State *L)
{
    try
    {
        auto lua = Lua.attach(L);

        auto args = lua.args();

        Log << format("Args: %s", to!string(args));
        
        return lua.result("called");
        
    } catch(Throwable)
    {
    }
    
    return 0;
}

luaL_Reg[] gimmelib = [
    luaL_Reg("gimme", &luaGimme),
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
    
    printout("show:", lua["show"].call(&luaGimme, 2, 3));
    //printout("show:", lua["show"].call(4, 5, 6));
    //printout("show:", lua["show"].call("A", 8, "B"));

static if(0) {

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

    //-------------------------------------------------------------------------
    // Register function and call it
    //-------------------------------------------------------------------------

    //lua.register("gimme", &luaGimme);
    lua.openlib("gimme", gimmelib);
    printout("gimme:", lua["gimme", "gimme"].call("A", 1, 2, "C"));
    printout("gimme:", lua["callgimme"].call());
    
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

