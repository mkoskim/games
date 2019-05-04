//*****************************************************************************
//
// Lua bindings, inspired by LuaD.
//
// This module is meant to make calls to Lua subsystem, and install D
// functions to Lua environment to be called.
//
// NOTE: Lua and D garbage collectors do not work nicely together. Main
// problem is with types requiring ref/unref, like tables and functions.
// Because of this, we need to simplify this code a lot, removing all
// sorts of automations. That makes it more laborous to call the
// functions and get results, but let's hope it won't matter that
// much for our purposes.
//
//*****************************************************************************

module engine.util.lua;

//-----------------------------------------------------------------------------

import std.variant: Variant;

import engine.asset.util;
import derelict.lua.lua;
static import std.conv;

//-----------------------------------------------------------------------------

class LuaError : Exception
{
    this(string msg) { super(msg); }
    this() { this("Lua error."); }
}

//*****************************************************************************
//
//*****************************************************************************

// TODO: Next, register D functions and call them
// TODO: Writing and reading array fields, creating arrays
// TODO: User data as parameter / return value

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

        luaL_requiref(L, "io", luaopen_io, 1);
        //luaL_requiref(L, "package", luaopen_package, 1);
        //luaL_requiref(L, "os", luaopen_os, 1);
        
        top = 0;
    }

    this(string file)
    {
        this();
        load(file);
    }

    //-----------------------------------------------------------------------------
    // This just wraps lua_State with interface class
    //-----------------------------------------------------------------------------

    static class Proxy : LuaInterface
    {
        protected this(lua_State *L) { super(L); }
    }

    static Proxy attach(lua_State *L) { return new Proxy(L); }
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

//*****************************************************************************
//
//
//
//*****************************************************************************

static if(0) class Dummy
{
    //-------------------------------------------------------------------------
    // Getting values from stack
    //-------------------------------------------------------------------------
    
    /*
    bool   toboolean(int index = -1) { return std.conv.to!bool(lua_toboolean(L, index)); }
    double tonumber(int index = -1)  { return lua_tonumber(L, index); }
    string tostring(int index = -1)  { return std.conv.to!(string)(lua_tostring(L, index)); }
    Value  tovalue(int index = -1)   { return new Value(this, index); }
    */

    //int    toref(int index = -1)     { lua_pushvalue(L, index); return luaL_ref(L, LUA_REGISTRYINDEX); }
    //void   unref(int id)             { luaL_unref(L, LUA_REGISTRYINDEX, id); }

    //-------------------------------------------------------------------------
    // Lua value wrapper for interfacing to D
    //-------------------------------------------------------------------------
    
    static class Value
    {
        union Payload {
            bool   _bool;
            double _number;
            string _string;
            void*  _data;
            int    _ref;
        }
        
        Type    type;
        Payload payload;

        //---------------------------------------------------------------------
        // Creating value from D type (to be pushed later)... One way to do
        // this: lua.push(bool); return lua.pop();
        //---------------------------------------------------------------------

/*
        this(T: bool)  (T value) { payload._bool   = value; type = Type.Bool; }
        this(T: int)   (T value) { payload._number = value; type = Type.Number; }
        this(T: float) (T value) { payload._number = value; type = Type.Number; }
        this(T: double)(T value) { payload._number = value; type = Type.Number; }
        this(T: string)(T value) { payload._string = value; type = Type.String; }
*/
        //---------------------------------------------------------------------
        // Creating value from stack. Do not use this directly, use
        // lua.tovalue() instead.
        //---------------------------------------------------------------------
        
        //---------------------------------------------------------------------

        ~this()
        {
            debug Track.remove(this);
            switch(type)
            {
                //case Type.Table:    lua.unref(payload._ref); break;
                //case Type.Function: lua.unref(payload._ref); break;
                default: break;
            }
        }

        //---------------------------------------------------------------------

        T to(T: string)()
        {
            switch(type)
            {
                case Type.Nil:      return "null";
                case Type.Bool:     return std.conv.to!string(payload._bool);
                case Type.Number:   return std.conv.to!string(payload._number);
                case Type.String:   return std.conv.to!string(payload._string);
                default:            ERROR(format("Invalid type: %s", std.conv.to!string(type)));
            }
            assert(0);
        }

        T to(T: int)()
        {
            switch(type)
            {
                case Type.Bool:     return std.conv.to!int(payload._bool);
                case Type.Number:   return std.conv.to!int(payload._number);
                default:            ERROR(format("Invalid type: %s", std.conv.to!string(type)));
            }
            assert(0);
        }

        //---------------------------------------------------------------------

        void push(Lua lua)
        {
            switch(type)
            {
                case Type.None:     return;
                case Type.Nil:      lua.push(); return;
                case Type.Bool:     lua.push(payload._bool); return;
                case Type.Number:   lua.push(payload._number); return;
                case Type.String:   lua.push(payload._string); return;
                //case Type.Table:    
                //case Type.Function: lua_rawgeti(lua.L, LUA_REGISTRYINDEX, payload._ref); return;

                default:
                case Type.UserData:
                case Type.LightUserData:
                case Type.Thread:   lua.error(); return;
            }
        }
        
        Value opIndex(U...)(U args)
        {
            errorif(type != Type.Table, "Not a table.");
            return lua.gettable(this, args);
        }

        Value[] keys()
        {
            errorif(type != Type.Table, "Not a table.");
            Value[] result;
            
            lua.push(this);
            lua.push();
            while(lua_next(lua.L, -2))
            {
                result ~= lua.tovalue(-2);
                lua.discard(1);
            }
            scope(exit) lua.discard(1);
            return result;
        }

        //---------------------------------------------------------------------

        Value[] opCall(U...)(U args)
        {
            errorif(type != Type.Function, "Not a function");

            lua.makeroom(args.length + 1);
            lua.push(this);
            foreach(arg; args) lua.push(arg);
            return lua._call();
        }        

        //---------------------------------------------------------------------

        void dumptable()
        {
            errorif(type != Type.Table, "Not a table.");
            
            //writefln("Table: 0x%08x", payload._ref);
            lua.push(this);
            lua.push();
            while(lua_next(lua.L, -2))
            {
                /*writefln("    [%s] = %s",
                    lua.tovalue(-2).to!string(),
                    lua.tovalue(-1).to!string()
                );
                */
                lua.discard(1);
            }
            lua.discard(1);
        }
    }        
}

