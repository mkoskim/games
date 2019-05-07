//*****************************************************************************
//
// Lua bindings, inspired by LuaD.
//
// This module is meant to make calls to Lua subsystem, and install D
// functions to Lua environment to be called.
//
// NOTE: Lua and D garbage collectors do not work nicely together. You need
// to be extra careful that you delete lua_State before carbage collector,
// and that you don't have loosen references outside of lua_State scope.
//
//*****************************************************************************

module engine.util.lua;

//-----------------------------------------------------------------------------

import engine.util;
import derelict.lua.lua;

import std.variant: Variant;
import std.conv: to;

//*****************************************************************************
//
//*****************************************************************************

class Lua : LuaInterface
{
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

    ~this()
    {
        Log("Top @ %d", top);
        lua_close(L);
        debug Track.remove(this);
    }

    this(string file)
    {
        this();
        load(file);
    }

    //-----------------------------------------------------------------------------
    // Attaching to lua_State (for D function implementations)
    //-----------------------------------------------------------------------------
    
    static Proxy attach(lua_State *L) { return new Proxy(L); }

    private static class Proxy : LuaInterface
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

    this(lua_State *L) { this.L = L; }
    
    //-------------------------------------------------------------------------
    // Access variables inside Lua sandbox
    //-------------------------------------------------------------------------

    void opIndexAssign(U)(U value, string key)
    {
        push(value);
        lua_setglobal(L, toStringz(key));
    }

    auto opIndex(string key)
    {
        return Ref(this, key);
    }

    //-------------------------------------------------------------------------
    // References to Lua data
    //-------------------------------------------------------------------------
    
    private struct Ref
    {
        LuaInterface lua;
        Type type;
        int  r;
        
        //---------------------------------------------------------------------
        
        this(LuaInterface lua, string key)
        {
            lua_getglobal(lua.L, toStringz(key));
            this(lua);
        }
        
        this(LuaInterface lua, int index)
        {
            lua_pushvalue(lua.L, index);
            this(lua);
        }
        
        private this(LuaInterface lua)
        {
            Track.add("Lua.Ref");
            this.lua = lua;
            type = lua.type();
            r    = luaL_ref(lua.L, LUA_REGISTRYINDEX);
            //lua.type() >> Log;
            //format("ref(%d)", r) >> Log;
        }
        
        this(this)
        {
            Track.add("Lua.Ref");
            lua_rawgeti(lua.L, LUA_REGISTRYINDEX, r);
            r = luaL_ref(lua.L, LUA_REGISTRYINDEX);
            //format("ref(%d)", r) >> Log;
        }

        ~this()
        {
            Track.remove("Lua.Ref");
            luaL_unref(lua.L, LUA_REGISTRYINDEX, r);
            //format("unref(%d)", r) >> Log;
        }
        
        @disable this();

        //---------------------------------------------------------------------

        auto opIndex(T)(T key)
        {
            lua.pusha(this, key);
            lua_gettable(lua.L, -2);
            scope(exit) lua.discard();
            return Ref(lua);
        }

        //---------------------------------------------------------------------

        // Set value
        void opIndexAssign(T, U)(U value, T key)
        {
            lua.pusha(this, key, value);
            lua_settable(lua.L, -3);
            lua.discard();
        }
        
        // Get value
        auto value()
        {
            lua.push(this);
            return lua.pop();
        }

        // Call
        auto call(T...)(T args)
        {
            lua.pusha(this, args);
            return lua._call(args.length);        
        }

        //---------------------------------------------------------------------

        auto keys()
        {
            lua.push(this);
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
        void push(string s)         { lua_pushlstring(L, s.ptr, s.length); }
        void push(char *s)          { lua_pushstring(L, s); }
        void push(char *s, int l)   { lua_pushlstring(L, s, l); }
        void push(Ref r)            { lua_rawgeti(L, LUA_REGISTRYINDEX, r.r); }
        
        //---------------------------------------------------------------------
        
        void push(void *p)          { lua_pushlightuserdata(L, p); }

        void push(lua_CFunction f)  { lua_pushcfunction(L, f); }
        void push(luaL_Reg[] ftable)
        {
            lua_newtable(L);
            luaL_setfuncs(L, ftable.ptr, 0);
        }

        //---------------------------------------------------------------------

        void push(Variant v)
        {
            if(v.peek!(bool)) push(v.get!(bool));
            else if(v.peek!(int)) push(v.get!(int));
            else if(v.peek!(float)) push(v.get!(float));
            else if(v.peek!(double)) push(v.get!(double));
            else if(v.peek!(string)) push(v.get!(string));
            else assert(false);
        }

        //---------------------------------------------------------------------

        int pusha(Variant[] values)
        {
            checkstack(cast(int)values.length);
            foreach(v; values) push(v);
            return cast(int)values.length;
        }

        int pusha(T...)(T values)
        {
            checkstack(values.length);
            foreach(v; values) push(v);
            return values.length;
        }
    }
    
    //-------------------------------------------------------------------------
    // Popping values
    //-------------------------------------------------------------------------

    private
    {
        enum Type // To get reference types to strings
        {
            None        = LUA_TNONE,
            Nil         = LUA_TNIL,
            Boolean     = LUA_TBOOLEAN,
            LUserData   = LUA_TLIGHTUSERDATA,
            Number      = LUA_TNUMBER,
            String      = LUA_TSTRING,
            Table       = LUA_TTABLE,
            Function    = LUA_TFUNCTION,
            UserData    = LUA_TUSERDATA,
            Thread      = LUA_TTHREAD,
            NumTags     = LUA_NUMTAGS,
        }
        
        auto type(int index = -1)     { return cast(Type)lua_type(L, index); }
        auto typename(int index = -1) { return type(index).to!string; }

        void expect(int expected, int index = -1)
        {
            errorif(type(index) != expected);
        }

        Variant peek(int index = -1)
        {
            switch(type(index))
            {
                case Type.Boolean:  return Variant(lua_toboolean(L, index));
                case Type.Number:   return Variant(lua_tonumber(L, index));
                case Type.String:   return Variant(lua_tostring(L, index).to!string);
                case Type.LUserData:
                case Type.UserData: return Variant(lua_touserdata(L, index));
                case Type.Function: 
                case Type.Table:    return Variant(Ref(this, index));
                case Type.Nil:
                default: break;
            }
            ERROR(format("Invalid type: %s", typename(index))); assert(0);
        }

        Variant pop()
        {
            scope(exit) discard();
            return peek();
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
        return pusha(results);
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

class LuaError : Exception
{
    this(string msg) { super(msg); }
    this() { this("Lua error."); }
}

//-----------------------------------------------------------------------------

