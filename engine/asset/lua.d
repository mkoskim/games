//*****************************************************************************
//
// Lua bindings, inspired by LuaD.
//
// Why not LuaD? Because it (1) segfaults, (2) supports only Lua 5.1, and
// (3) uses its own statically linked liblua.
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
    lua_State *L;
    bool owner;
        
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
    
    this()
    {
        L = luaL_newstate();
        owner = true;

        //luaL_openlibs(L);

        luaL_requiref(L, "_G", luaopen_base, 1);
        luaL_requiref(L, "string", luaopen_string, 1);
        luaL_requiref(L, "table", luaopen_table, 1);
        luaL_requiref(L, "math", luaopen_math, 1);

        //luaL_requiref(L, "io", luaopen_io, 1);
        //luaL_requiref(L, "package", luaopen_package, 1);
        //luaL_requiref(L, "os", luaopen_os, 1);
/*
        //luaopen_debug(L);
        //luaopen_os(L);
*/        
        lua_settop(L, 0);
    }

    this(lua_State *L) {
        this.L = L;
        owner = false;
    }

    this(string file)
    {
        this();
        load(file);
    }

    ~this() {
        if(owner) lua_close(L);
    }

    //-------------------------------------------------------------------------

    void push()                { lua_pushnil(L); } 
    void push(bool b)          { lua_pushboolean(L, b); }
    void push(int  i)          { lua_pushnumber(L, i); }
    void push(float f)         { lua_pushnumber(L, f); }
    void push(double d)        { lua_pushnumber(L, d); }
    void push(char *s, int l)  { lua_pushlstring(L, s, l); }
    void push(string s)        { lua_pushlstring(L, s.ptr, s.length); }

    auto type(int index = -1) { return lua_type(L, index); }

    Variant lookup(int index = -1)
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
    
    Variant pop()
    {
        scope(exit) { lua_pop(L, 1); }
        return lookup();
    }

    Variant call(int argc, int retc)
    {
        lua_call(L, argc, retc);

        scope(exit) { lua_settop(L, 0); }
        
        return lua_gettop(L) ? pop() : Variant(null);
    }
    
    Variant call(string f, ...)
    {
        int  argc = cast(int)_arguments.length;
        
        lua_checkstack(L, argc + 1);
        lua_getglobal(L, f.toStringz);
        
        assert(type() == LUA_TFUNCTION);
                
        foreach(arg; _arguments) {
            if     (arg == typeid(bool))   push(va_arg!(bool)(_argptr));
            else if(arg == typeid(int))    push(va_arg!(int)(_argptr));
            else if(arg == typeid(float))  push(va_arg!(float)(_argptr));
            else if(arg == typeid(double)) push(va_arg!(double)(_argptr));
            else if(arg == typeid(string)) push(va_arg!(string)(_argptr));
            else assert(false);
        }
        
        return call(argc, 1);
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
    
    Variant eval(string s)
    {
        checklua(luaL_loadstring(L, toStringz(s)));
        return call(0, 1);
    }

    Variant load(string s)
    {
        return eval(blob.text(s));
    }
}

