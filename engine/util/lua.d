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

import std.string: toStringz;
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

// TODO: Writing and reading array fields, creating arrays
// TODO: User data as parameter / return value
// TODO: Register D functions inside a table (name space)

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
    //      lua["math", "abs"].call(100);       // math.abs = function
    //      lua["math"].keys();                 // math = table
    //
    //-------------------------------------------------------------------------

    Top opIndex(U...)(string root, U args)
    {
        lua_getglobal(L, toStringz(root));
        foreach(key; args)
        {
            push(key);
            lua_gettable(L, -2);
        }
        return new Top();
    }

    class Top
    {
        auto call(U...)(U args)
        {
            expect(Type.Function);
            makeroom(args.length + 1);

            foreach(arg; args) push(arg);
            
            return _call(args.length);        
        }
        
        auto get()
        {
            return pop();
        }
    }

    //-------------------------------------------------------------------------
    // Stack management & inspection
    //-------------------------------------------------------------------------

    private
    {
        @property int  top()          { return lua_gettop(L); }
        @property void top(int index) { lua_settop(L, index); }
        void makeroom(int elems)      { lua_checkstack(L, elems); }
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

            expect(Type.Function, frame);
            lua_call(L, argc, LUA_MULTRET);
            return pop(top - frame + 1);
        }
    }
            
    //-------------------------------------------------------------------------
    // Pushing arguments to stack
    //-------------------------------------------------------------------------
    
    private 
    {
        void push()                 { lua_pushnil(L); } 
        void push(bool b)           { lua_pushboolean(L, b); }
        void push(int  i)           { lua_pushnumber(L, i); }
        void push(float f)          { lua_pushnumber(L, f); }
        void push(double d)         { lua_pushnumber(L, d); }
        void push(char *s)          { lua_pushstring(L, s); }
        void push(char *s, int l)   { lua_pushlstring(L, s, l); }
        void push(string s)         { lua_pushlstring(L, s.ptr, s.length); }
    }
    
    //-------------------------------------------------------------------------
    // Lua value types
    //-------------------------------------------------------------------------

    private
    {
        enum Type
        {
            None            = LUA_TNONE,
            Nil             = LUA_TNIL,
            Bool            = LUA_TBOOLEAN,
            Number          = LUA_TNUMBER,
            String          = LUA_TSTRING,
            UserData        = LUA_TUSERDATA,
            LightUserData   = LUA_TLIGHTUSERDATA,
            Table           = LUA_TTABLE,
            Function        = LUA_TFUNCTION,
            Thread          = LUA_TTHREAD,
        }

        Type type(int index = -1) { return cast(Type)lua_type(L, index); }

        void expect(int expected, int index = -1)
        {
            errorif(type(index) != expected, "Wrong type.");
        }

        Variant get(int index)
        {
            switch(type(index))
            {
                case Type.Nil:      return Variant(null);
                case Type.Bool:     return Variant(lua_toboolean(L, index));
                case Type.Number:   return Variant(lua_tonumber(L, index));
                case Type.String:   return Variant(lua_tostring(L, index));
                default: break;
            }
            ERROR(format("Invalid type: %s", to!string(type(index)))); assert(0);
        }

        Variant pop()
        {
            scope(exit) discard(1);
            return get(-1);
        }

        Variant[] pop(int n = 1)
        {
            scope(exit) discard(n);
            
            Variant[] ret = new Variant[n];
            foreach(i; 0 .. n) ret[i] = get(top - n + i + 1);
            return ret;
        }

        void discard(int n) { lua_pop(L, n); }
        }
    
    //-------------------------------------------------------------------------
    // D functions
    //-------------------------------------------------------------------------

    void register(string name, lua_CFunction f)
    {
        lua_register(L, toStringz(name), f);
    }

    Variant[] args()
    {
        return pop(top());
    }

    int result(T...)(T results)
    {
        foreach(r; results) push(r);
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

