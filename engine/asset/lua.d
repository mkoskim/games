//*****************************************************************************
//
// Lua bindings, heavily inspired by LuaD.
//
// Why not LuaD? Because it (1) segfaults, (2) supports only Lua 5.1, and
// (3) uses its own statically linked liblua. I would anyways need to make
// a local branch from that...
//
//*****************************************************************************

module engine.asset.lua;

//-----------------------------------------------------------------------------

import engine.asset.util;
import blob = engine.asset.blob;

import derelict.lua.lua;
import std.variant: Variant;
import core.vararg;

//-----------------------------------------------------------------------------

class Lua
{
    //-------------------------------------------------------------------------
    //
    // Lua state setup. This is mainly responsible for deallocating
    // state when it is not needed anymore.
    //
    //-------------------------------------------------------------------------
    
    private class State
    {
        lua_State *L;

        this()
        {
            L = luaL_newstate();

            luaL_requiref(L, "_G", luaopen_base, 1);
            luaL_requiref(L, "string", luaopen_string, 1);
            luaL_requiref(L, "table", luaopen_table, 1);
            luaL_requiref(L, "math", luaopen_math, 1);

            //luaL_requiref(L, "io", luaopen_io, 1);
            //luaL_requiref(L, "package", luaopen_package, 1);
            //luaL_requiref(L, "os", luaopen_os, 1);
            lua_settop(L, 0);
        }
        ~this() { lua_close(L); }
    }

    private State state;
    
    //-------------------------------------------------------------------------
    // Lua interface
    //-------------------------------------------------------------------------
    
    lua_State *L;
        
    this(lua_State *L) { this.L = L; }
    this(Lua lua)      { this(lua.state.L); }
    
    this()
    {
        state = new State();
        this(state.L);
    }

    this(string file)
    {
        this();
        load(file);
    }

    ~this() { }

    //-------------------------------------------------------------------------

    void checklua(int errno)
    {
        if(errno != LUA_OK)
        {
            lua_error(L);
            assert(false);
        }
    }

    //-------------------------------------------------------------------------
    // Loading Lua functions
    //-------------------------------------------------------------------------
    
    Variant eval(string s, string from = "string")
    {
        checklua(luaL_loadbuffer(L, s.ptr, s.length, toStringz(from)));
        return _call();
    }

    Variant load(string s)
    {
        return eval(blob.text(s), s);
    }

    //-------------------------------------------------------------------------
    // Pushing arguments to stack
    //-------------------------------------------------------------------------
    
    void push()                { lua_pushnil(L); } 
    void push(bool b)          { lua_pushboolean(L, b); }
    void push(int  i)          { lua_pushnumber(L, i); }
    void push(float f)         { lua_pushnumber(L, f); }
    void push(double d)        { lua_pushnumber(L, d); }
    void push(char *s, int l)  { lua_pushlstring(L, s, l); }
    void push(string s)        { lua_pushlstring(L, s.ptr, s.length); }

    //-------------------------------------------------------------------------
    // Stack inspection
    //-------------------------------------------------------------------------
    
    auto type(int index = -1) { return lua_type(L, index); }

    Variant fetch(int index = -1)
    {
        final switch(type(index))
        {
            case LUA_TNONE: 
            case LUA_TTABLE:   
            case LUA_TFUNCTION:
            case LUA_TUSERDATA:
            case LUA_TTHREAD:  
            case LUA_TLIGHTUSERDATA:
                writeln("Stack top = ", TypeName[type(index)]);
                assert(false);
            
            case LUA_TNIL:     return Variant(null);
            case LUA_TNUMBER:  return Variant(lua_tonumber(L, index));
            case LUA_TBOOLEAN: return Variant(lua_toboolean(L, index));
            case LUA_TSTRING:  return Variant(lua_tostring(L, index));
        }
    }
    
    //-------------------------------------------------------------------------
    // Popping values from stack
    //-------------------------------------------------------------------------

    Variant pop()
    {
        scope(exit) { lua_pop(L, 1); }
        return fetch();
    }

    //-------------------------------------------------------------------------
    // Making calls to Lua functions
    //-------------------------------------------------------------------------
    
    private void getglobal(string s, int t)
    {
        lua_getglobal(L, s.toStringz);
        assert(type() == t);
    }

    private Variant _call(int argc, int retc = LUA_MULTRET)
    {
        lua_call(L, argc, retc);

        dump("return:");
        scope(exit) { lua_settop(L, 0); }
        
        return lua_gettop(L) ? pop() : Variant(null);
    }
    
    private Variant _call()
    {
        return _call(lua_gettop(L) - 1);
    }
    
    Variant call(U...)(string f, U args)
    {
        int  argc = cast(int)args.length;
        
        lua_checkstack(L, argc + 1);
        
        getglobal(f, LUA_TFUNCTION); 
        foreach(arg; args) push(arg);
        dump("call:");
        return _call();
    }
            
    //-------------------------------------------------------------------------

    const enum string[int] TypeName = [
        LUA_TNONE: "None",
        LUA_TTABLE: "Table",
        LUA_TFUNCTION: "Function",
        LUA_TUSERDATA: "UserData",
        LUA_TTHREAD:  "Thread",
        LUA_TLIGHTUSERDATA: "LightUserData",
        LUA_TNIL: "Nil",
        LUA_TNUMBER: "Number",
        LUA_TBOOLEAN: "Bool",
        LUA_TSTRING: "String",
    ];

    //-------------------------------------------------------------------------

    void dump(string prefix)
    {
        int top = lua_gettop(L);
        writeln(prefix);
        foreach(i; 1 .. top + 1) writefln("    [%d] : %s", i, TypeName[type(i)]);
    }    
}

