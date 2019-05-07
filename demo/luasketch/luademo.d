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
    foreach(arg; args) format("    %s", arg.to!string) >> Log;
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

//-----------------------------------------------------------------------------

extern(C) nothrow int bounceback(lua_State *L)
{
    try
    {
        auto lua = Lua.attach(L);
        auto args = lua.args();
        return lua.result(args);
    }
    catch(Throwable)
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

auto test()
{
    {
        lua_State *L = luaL_newstate();
        luaL_requiref(L, "_G", luaopen_base, 1);
        lua_pop(L, 1);

        lua_getglobal(L, toStringz("_G"));
        format("type@%d = %s", lua_gettop(L), luaL_typename(L, -1).to!string) >> Log;
        int t1 = lua_type(L, -1);
        auto r = luaL_ref(L, LUA_REGISTRYINDEX);
        lua_rawgeti(L, LUA_REGISTRYINDEX, r);
        format("type@%d = %s", lua_gettop(L), luaL_typename(L, -1).to!string) >> Log;
        int t2 = lua_type(L, -1);
        format("ref(%d)", r) >> Log;

        lua_close(L);

        assert((t1 != LUA_TNIL) && (t1 == t2));
    }
    
    auto lua = new Lua();
    scope(exit) { lua.destroy(); }

static if(0) {

    //-------------------------------------------------------------------------
    
    //printout("main.lua returns:", lua.load("data/main.lua"));

    //-------------------------------------------------------------------------
    
    printout("test.lua returns:", lua.load("data/test.lua"));

    //-------------------------------------------------------------------------
    // Inspect table created in lua file
    //-------------------------------------------------------------------------

    lua["mytable"].value();

    printout("mytable['a'] = ", lua["mytable"]["a"].value());
    printout("mytable['c'][1] = ", lua["mytable"]["c"][1].value());

    printout("mytable[1]   = ", lua["mytable"][1].value());
    printout("mytable['1'] = ", lua["mytable"]["1"].value());

    //-------------------------------------------------------------------------
    
    lua["a"] = 101;
    lua["a"].value() >> Log;

    lua["mytable"]["c"][1] = "c";
    lua["mytable"]["c"][1].value() >> Log;

    lua["show"].call(1, 2, 3) >> Log;

    //-------------------------------------------------------------------------
    // Call lua function:
    //-------------------------------------------------------------------------
    
    printout("show:", lua["show"].call(1, 2, 3));
    printout("show:", lua["show"].call(4, 5, 6));
    printout("show:", lua["show"].call("A", 8, "B"));
    //printout("show:", lua["show"].call(&bounceback, 2, 3));

    //-------------------------------------------------------------------------
    // Check multi return
    //-------------------------------------------------------------------------

    printout("multiret:", lua["multiret"].call());
    
    //-------------------------------------------------------------------------
    // Inspect tables
    //-------------------------------------------------------------------------
    
    printout("Keys:", lua["mytable"].keys());
    printout("_G:", lua["_G"].keys());

    //-------------------------------------------------------------------------
    // Call function via table: string.format
    //-------------------------------------------------------------------------
    
    printout("string.format:", lua["string"]["format"].call("Test %d", 12));

    //-------------------------------------------------------------------------
    // Register function and call it
    //-------------------------------------------------------------------------

    lua["gbounce"] = &bounceback;
    lua["gbounce"].call("global", "bounce") >> Log;

    lua["mytable"]["bounce"] = &bounceback;
    lua["mytable"]["bounce"].call("mytable", "bounce") >> Log;

    lua["bounce"] = bouncelib;
    lua["bounce"]["bounceback"].call("bounce", "lib") >> Log;

    printout("callbounce:", lua["callbounce"].call(1));

    //-------------------------------------------------------------------------
    // Fixed: Leaves carbage to stack
    //-------------------------------------------------------------------------

    lua["show"];

    //-------------------------------------------------------------------------
    // Get reference to string, and use it to call format
    //-------------------------------------------------------------------------
    
    {
        auto luashow = lua["show"];
        luashow.call(1);
        luashow.call(2);
        auto multiret = lua["multiret"];
        printout("luashow", luashow.call(1));
    }
    
    {
        auto stringlib = lua["string"];
        printout(
            "string.format:",
            stringlib["format"].call("%s.%s (1)", "string", "format")
        );
        printout(
            "string.format:",
            stringlib["format"].call("%s.%s (2)", "string", "format")
        );
    }

    //-------------------------------------------------------------------------
    // howdy() returns table, check it
    //-------------------------------------------------------------------------

/*
    auto howdy = lua["howdy"];
    writeln("howdy = ", howdy.type);
    
    auto ret = howdy();
    
    printout("howdy():", ret);
    ret[0].dumptable();
/**/

}
    //-------------------------------------------------------------------------

    "Done." >> Log;

    //-------------------------------------------------------------------------
    // Another way to get ref out from scope.
    //-------------------------------------------------------------------------

    //return lua["mytable"];
}

void main()
{
    vfs.fallback = true;

    test();

    // It might be good idea to run GC after assets are loaded (I
    // think it will produce lots of memory allocations).

    Track.GC.run();
    debug Track.report();

    "All done." >> Log;
}

