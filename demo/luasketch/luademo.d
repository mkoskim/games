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

class TestClass1
{
    string name;
    
    this(string name) { this.name = name; }
}

class TestClass2
{
    string name;
    
    this(string name) { this.name = name; }
}

//-----------------------------------------------------------------------------

extern(C) nothrow int bounceback(lua_State *L)
{
    try
    {
        auto lua = Lua.attach(L);
        auto args = lua.args();
        Log("called: bounce(%s)", args);
        return lua.result(args);
    }
    catch(Throwable e)
    {
        try e >> Log; catch(Throwable) {}
        assert(0);
    }
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
    auto lua = new Lua();
    scope(exit) { lua.destroy(); }

    //-------------------------------------------------------------------------
    
    lua["_VERSION"].value >> Log;
    lua.load("data/test.lua").to!string >> Log;

    //-------------------------------------------------------------------------
    // Get reference to string, and use it to call format
    //-------------------------------------------------------------------------
    
    {
        auto luashow = lua["show"];
        luashow.call("1", "2", "3");
        luashow.call("4", "5", "6");
        auto multiret = lua["multiret"];
        printout("luashow", luashow.call("7", "8", "9"));
    }
    
    {
        lua["string"]["format"].call("Test: %s %d", "test", 1) >> Log;

        auto stringlib = lua["string"];
        auto stringfmt = stringlib["format"];
        
        stringlib.to!string >> Log;
        stringlib["format"].to!string >> Log;
        stringfmt.to!string >> Log;

        stringlib["format"].call("%s.%s (%d)", "string", "format", 2) >> Log;
        stringfmt.call("%s.%s (%d)", "string", "format", 1) >> Log;
    }

static if(0) {

    //-------------------------------------------------------------------------
    // Sending and receiving D objects
    //-------------------------------------------------------------------------

    {
        auto a = new TestClass2("a");
        lua["print"].call(a);
        auto r = lua.call(&bounceback, a);
        r >> Log;
        //r[0].get!(Object*) >> Log;
        //(cast(Object)r[0].get!(void*)).classinfo.toString >> Log;
        //(cast(TestClass1)r[0].get!(void*)).name >> Log;
    }

    //-------------------------------------------------------------------------
    // These are "equal" (one is Ref, another is Variant(Ref)
    //-------------------------------------------------------------------------

    lua["math"] >> Log;         // Ref 2 table
    lua["math"].value >> Log;   // Variant(Ref 2 table)

    //-------------------------------------------------------------------------
    // These are not. First is Ref, another is Variant(3.14)
    //-------------------------------------------------------------------------

    lua["math"]["pi"] >> Log;       // Ref 2 number
    lua["math"]["pi"].value >> Log; // Variant(3.14)

    //lua["math"]["abs"]["x"] = 1; // Should crash

    //-------------------------------------------------------------------------
    // Inspect table created in lua file
    //-------------------------------------------------------------------------

    //lua["mytable"].value();

    printout("mytable['a'] = ", lua["mytable"]["a"].value);
    printout("mytable['c'][1] = ", lua["mytable"]["c"][1].value);

    printout("mytable[1]   = ", lua["mytable"][1].value);
    printout("mytable['1'] = ", lua["mytable"]["1"].value);

    //-------------------------------------------------------------------------
    
    lua["a"] = 101;
    lua["a"].value() >> Log;

    lua["mytable"]["c"][1] = "c";
    lua["mytable"]["c"][1].value() >> Log;

    lua["show"].call(1, 2, 3) >> Log;

    //-------------------------------------------------------------------------
    // Call lua function:
    //-------------------------------------------------------------------------
    
    printout("show:", lua["show"].call(1, 2, lua["math"]));
    printout("show:", lua["show"].call(4, 5, lua["math"]["abs"]));
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
