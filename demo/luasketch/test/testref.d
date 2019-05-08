//-----------------------------------------------------------------------------
//
// Investigating problems with references on Windows builds.
//
//-----------------------------------------------------------------------------

import derelict.lua.lua;
import std.string: toStringz;
import std.stdio: writefln;

void main()
{
    version(linux)
    {
        DerelictLua.load("liblua5.3.so");        
    } else {
        DerelictLua.load();
    }

    lua_State *L = luaL_newstate();
    luaL_requiref(L, "_G", luaopen_base, 1);
    lua_pop(L, 1);

    lua_getglobal(L, toStringz("_G"));
    int t1 = lua_type(L, -1);
    auto r = luaL_ref(L, LUA_REGISTRYINDEX);
    
    lua_rawgeti(L, LUA_REGISTRYINDEX, r);
    int t2 = lua_type(L, -1);
    
    lua_close(L);

    // Linux output: Ref: 3, types: 5, 5
    writefln("Ref: %d, types: %d, %d", r, t1, t2);
    
    assert(r != LUA_REFNIL);
    assert((t1 != LUA_TNIL) && (t1 == t2));
}

