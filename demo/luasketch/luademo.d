//*****************************************************************************
//
// Sketching plugging LUA to game engine.
//
//*****************************************************************************

import engine;
import engine.game: Track;

import std.stdio;

alias engine.asset.Lua.LuaType LuaType;
alias engine.asset.Lua.LuaObject LuaObject;

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
    //{ "gimme", &luaGimme },
    //{ "crash", &luaCrash },
    { null, null },
];

//-----------------------------------------------------------------------------
// Creating interface for LUA to access D functions
//-----------------------------------------------------------------------------

void show(LuaObject[] result)
{
    write("(");
    foreach(r; result) switch(r.type)
    {
        case LuaType.Bool:
        case LuaType.Number:
        case LuaType.String:
            write(r.value); write(", "); break;
        default:
            write(r.type); write(", "); break;
    }
    writeln(")");
}

void test()
{
    auto lua = new engine.asset.Lua();

    luaL_register(lua.L, "_G", globals.ptr);
    lua.top = 0;

    lua.load("data/test.lua");

    show(
        lua["string", "format"]("Test %d", 12)
    );

    auto stringlib = lua["string"];
    show(stringlib["format"]("Test %d", 13));

    auto howdy = lua["howdy"];

    writeln("howdy = ", howdy.type);    
    write("howdy() returns: "); show(howdy());

/*


//*
    writeln(
        "show() returns: ",
        lua.gettable(null, "show").get!Reference(1.2, 3.4, 5.6)
    );

    writeln(
        "main.lua returns: ",
        lua.load("data/main.lua")
    );    
/**/
    Track.report();
    writeln("Done.");
}

void main()
{
    test();
    Track.rungc();
}

