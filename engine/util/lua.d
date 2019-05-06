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
    // BUG: If none of the final operations are called, this mechanism
    // leaves two values to stack:
    //
    //      lua["math"]["abs"];     // Two values left to stack
    //
    // Adding stack cleaning to destructor won't help, it leads to segfault
    // at least when program terminates.
    //
    //-------------------------------------------------------------------------

    Top opIndex(T)(T arg)
    {
        lua_getglobal(L, toStringz("_G"));
        push(arg);
        return Top(this);
    }

    private struct Top
    {
        LuaInterface lua;
        int top;
        
        this(LuaInterface lua)
        {
            this.lua = lua;
            this.top = lua.top;
        }
        
        ~this()
        {
            if(top == lua.top) lua.discard(2);
        }

        @disable this(this);
        
        // Go deeper to table hierarchy
        ref Top opIndex(T)(T arg)
        in(lua.top == top)
        {
            lua_gettable(lua.L, -2);
            lua_remove(lua.L, -2);
            lua.push(arg);
            return this;
        }

        // Call head
        auto call(T...)(T args)
        in(lua.top == top)
        {
            lua_gettable(lua.L, -2);
            lua.expect(LUA_TFUNCTION);

            lua.pushargs(args);
            
            scope(exit) lua.discard();
            return lua._call(args.length);        
        }
        
        // Get head value
        auto get()
        in(lua.top == top)
        {
            lua_gettable(lua.L, -2);
            scope(exit) lua.discard();
            return lua.pop();
        }

        // Set head value
        void set(T)(T value)
        in(lua.top == top)
        {
            lua.push(value);
            _set();
        }

        void set(lua_CFunction f)
        in(lua.top == top)
        {
            lua_pushcfunction(lua.L, f);
            _set();
        }

        void set(luaL_Reg[] ftable)
        in(lua.top == top)
        {
            lua_newtable(lua.L);
            luaL_setfuncs(lua.L, ftable.ptr, 0);
            _set();
        }

        private void _set()
        {
            lua_settable(lua.L, -3);
            lua.discard();
        }

        // Get table keys. Mainly for debugging purposes
        auto keys()
        in(lua.top == top)
        {
            lua_gettable(lua.L, -2);
            lua_remove(lua.L, -2);

            Variant[] k;
            lua_pushnil(lua.L);
            while(lua_next(lua.L, -2) != 0)
            {
                lua.discard();
                k ~= lua.peek(-1);
            }
            scope(exit) lua.discard();
            return k;
        }
    }

    //-------------------------------------------------------------------------
    // Load & execute Lua scripts
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
    // Stack management & inspection
    //-------------------------------------------------------------------------

    private
    {
        @property int  top()          { return lua_gettop(L); }
        @property void top(int index) { lua_settop(L, index); }
        void checkstack(int elems)    { lua_checkstack(L, elems); }
    }

    //-------------------------------------------------------------------------
    // Pushing arguments to stack
    //-------------------------------------------------------------------------
    
    private 
    {
        void push(bool b)           { lua_pushboolean(L, b); }
        void push(int  i)           { lua_pushnumber(L, i); }
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
                case LUA_TBOOLEAN:  return Variant(lua_toboolean(L, index));
                case LUA_TNUMBER:   return Variant(lua_tonumber(L, index));
                case LUA_TSTRING:   return Variant(lua_tostring(L, index));
                case LUA_TUSERDATA:
                case LUA_TLIGHTUSERDATA: return Variant(lua_touserdata(L, index));

                case LUA_TNONE:
                case LUA_TNIL:      //return Variant(null);
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
    // Args & return values for D functions
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
