//*****************************************************************************
//
// Lua bindings, inspired by LuaD.
//
// This module is meant to make calls to Lua subsystem, and install D
// functions to Lua environment to be called.
//
//*****************************************************************************

module engine.util.lua;

//-----------------------------------------------------------------------------

import engine.util;
import derelict.lua.lua;

import std.variant: Variant;
import std.conv: to;

//-----------------------------------------------------------------------------

class LuaError : Exception
{
    this(string msg) { super(msg); }
    this() { this("Lua error."); }
}

//*****************************************************************************
//
//*****************************************************************************

// NOTE: Lua and D garbage collectors do not work nicely together.
// Main problem are references (luaL_ref, luaL_unref). It is better not to
// take them, and if you do, it is good to keep the scope limited, and ensure
// that ref gets undone.

//-----------------------------------------------------------------------------
// This creates actual Lua sandbox
//-----------------------------------------------------------------------------

class Lua : LuaInterface
{
    ~this()
    {
        Log << format("Top @ %d", top);
        lua_close(L);
        debug Track.remove(this);
    }

    this()
    {
        debug Track.add(this);
        super(luaL_newstate());

        luaL_requiref(L, "_G", luaopen_base, 1);
        luaL_requiref(L, "string", luaopen_string, 1);
        luaL_requiref(L, "table", luaopen_table, 1);
        luaL_requiref(L, "math", luaopen_math, 1);
        luaL_requiref(L, "debug", luaopen_debug, 1);

        //luaL_requiref(L, "io", luaopen_io, 1);
        //luaL_requiref(L, "package", luaopen_package, 1);
        //luaL_requiref(L, "os", luaopen_os, 1);
        
        top = 0;
    }

    this(string file)
    {
        this();
        load(file);
    }

    static Proxy attach(lua_State *L) { return new Proxy(L); }

    //-----------------------------------------------------------------------------
    // This just wraps lua_State with interface class
    //-----------------------------------------------------------------------------

    protected static class Proxy : LuaInterface
    {
        this(lua_State *L) { super(L); }
    }
}

//*****************************************************************************
//
// Actual Lua interface
//
//*****************************************************************************

abstract class LuaInterface
{
    private lua_State *L;

    //-------------------------------------------------------------------------

    this(lua_State *L)
    {
        this.L = L;
    }

    //-------------------------------------------------------------------------
    // First, get identifier at the top of stack with indexing. Then, use
    // Top object returned by indexing. For example:
    //
    //      lua["math"]["abs"].call(100);       // math.abs = function
    //      lua["math"].keys();                 // math = table
    //
    //-------------------------------------------------------------------------

    Top opIndex(T)(T arg)
    {
        lua_getglobal(L, toStringz("_G"));
        push(arg);
        return new Top();
    }

    private class Top
    {
        auto opIndex(T)(T arg)
        {
            lua_gettable(L, -2);
            lua_remove(L, -2);
            push(arg);
            return this;
        }

        auto call(T...)(T args)
        {
            lua_gettable(L, -2);
            expect(LUA_TFUNCTION);

            pushargs(args);
            
            scope(exit) discard();
            return _call(args.length);        
        }
        
        auto get()
        {
            lua_gettable(L, -2);
            scope(exit) discard();
            return pop();
        }

        void set(lua_CFunction f)
        {
            lua_pushcfunction(L, f);
            lua_settable(L, -3);
            discard();
        }

        void set(luaL_Reg[] ftable)
        {
            lua_newtable(L);
            luaL_setfuncs(L, ftable.ptr, 0);
            lua_settable(L, -3);
            discard();
        }

        void set(T)(T value)
        {
            push(value);
            lua_settable(L, -3);
            discard();
        }

        auto keys()
        {
            lua_gettable(L, -2);
            lua_remove(L, -2);

            Variant[] k;
            lua_pushnil(L);
            while(lua_next(L, -2) != 0)
            {
                discard();
                k ~= peek(-1);
            }
            scope(exit) discard();
            return k;
        }

    }

    //-------------------------------------------------------------------------
    // Stack management & inspection
    //-------------------------------------------------------------------------

    private
    {
        @property int  top()          { return lua_gettop(L); }
        @property void top(int index) { lua_settop(L, index); }
        void checkstack(int elems)    { lua_checkstack(L, elems); }
    }

    //-------------------------------------------------------------------------
    // Loading Lua functions
    //-------------------------------------------------------------------------
    
    auto load(string s)
    {
        return eval(vfs.text(s), s);
    }

    auto eval(string s, string from = "string")
    {
        check(luaL_loadbuffer(L, s.ptr, s.length, toStringz(from)));
        return _call();
    }

    private
    {
        auto _call(int argc = 0)
        {
            int frame = top - argc;

            expect(LUA_TFUNCTION, frame);
            lua_call(L, argc, LUA_MULTRET);
            return pop(top - frame + 1);
        }
    }

    //-------------------------------------------------------------------------
    // Pushing arguments to stack
    //-------------------------------------------------------------------------
    
    private 
    {
        void push(bool b)           { lua_pushboolean(L, b); }
        void push(int  i)           { lua_pushinteger(L, i); }
        void push(long l)           { lua_pushinteger(L, l); }
        void push(float f)          { lua_pushnumber(L, f); }
        void push(double d)         { lua_pushnumber(L, d); }
        void push(char *s)          { lua_pushstring(L, s); }
        void push(char *s, int l)   { lua_pushlstring(L, s, l); }
        void push(string s)         { lua_pushlstring(L, s.ptr, s.length); }
        void push(void *p)          { lua_pushlightuserdata(L, p); }

        void pushargs(T...)(T values)
        {
            checkstack(values.length);
            foreach(v; values) push(v);
        }
    }
    
    //-------------------------------------------------------------------------
    // Popping values
    //-------------------------------------------------------------------------

    private
    {
        int type(int index = -1) { return lua_type(L, index); }

        void expect(int expected, int index = -1)
        {
            errorif(type(index) != expected, format("Wrong type: %d != %d", type(index), expected));
        }

        Variant peek(int index)
        {
            switch(type(index))
            {
                case LUA_TNIL:      return Variant(null);
                case LUA_TBOOLEAN:  return Variant(lua_toboolean(L, index));
                case LUA_TNUMBER:   return Variant(lua_tonumber(L, index));
                case LUA_TSTRING:   return Variant(lua_tostring(L, index));
                case LUA_TUSERDATA:
                case LUA_TLIGHTUSERDATA: return Variant(lua_touserdata(L, index));

                case LUA_TNONE:
                case LUA_TTABLE:
                case LUA_TFUNCTION:
                case LUA_TTHREAD:
                default: break;
            }
            ERROR(format("Invalid type: %s", to!string(type(index)))); assert(0);
        }

        Variant pop()
        {
            scope(exit) discard(1);
            return peek(-1);
        }

        Variant[] pop(int n)
        {
            scope(exit) discard(n);
            
            Variant[] ret = new Variant[n];
            foreach(i; 0 .. n) ret[i] = peek(top - n + i + 1);
            return ret;
        }

        void discard(int n = 1) { lua_pop(L, n); }
    }
    
    //-------------------------------------------------------------------------
    // D functions
    //-------------------------------------------------------------------------

    Variant[] args()
    {
        return pop(top());
    }

    int result(T...)(T results)
    {
        pushargs(results);
        return results.length;
    }

    //-------------------------------------------------------------------------
    // Lua sandbox errors
    //-------------------------------------------------------------------------

    private
    {
        void error(string msg) { throw new LuaError(msg); }
        void error()           { error("Unknown error");  }

        void errorif(bool cond) { if(cond) error(); }
        void errorif(bool cond, lazy string msg) { if(cond) error(msg); }
        
        void check(int errcode) { errorif(errcode != LUA_OK, to!string(pop())); }
    }
}

