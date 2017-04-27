//*****************************************************************************
//
// Lua bindings, heavily inspired by LuaD.
//
// This module is sort of striped down LuaD, to call Lua functions, and set
// up D based backend for scripts.
//
//*****************************************************************************

module engine.asset.lua;

//-----------------------------------------------------------------------------

import engine.asset.util;
import blob = engine.asset.blob;

import derelict.lua.lua;
import std.variant: Variant;
static import std.conv;

//-----------------------------------------------------------------------------

class LuaError : Exception {
    this(string msg) { super(msg); }
    this() { this("Lua error."); }
}

//*****************************************************************************
//
// Lua is lightweight (8 bytes) wrapper to lua_State.
//
//*****************************************************************************

class Lua
{
    //-------------------------------------------------------------------------
    // Lua interface creation
    //-------------------------------------------------------------------------
    
    lua_State *L;
    private bool isOwner;

    //-------------------------------------------------------------------------

    this(lua_State *L, bool owner = false)
    {
        debug Track.add(this);
        this.L = L;
        this.isOwner = owner;
    }

    this()
    {
        this(luaL_newstate(), true);

        luaL_requiref(L, "_G", luaopen_base, 1);
        luaL_requiref(L, "string", luaopen_string, 1);
        luaL_requiref(L, "table", luaopen_table, 1);
        luaL_requiref(L, "math", luaopen_math, 1);

        //luaL_requiref(L, "package", luaopen_package, 1);
        //luaL_requiref(L, "io", luaopen_io, 1);
        //luaL_requiref(L, "os", luaopen_os, 1);
        
        top = 0;
    }

    this(string file)
    {
        this();
        load(file);
    }

    ~this() {
        Track.remove(this);
        if(isOwner) lua_close(L);
    }

    //-------------------------------------------------------------------------
    // Error management
    //-------------------------------------------------------------------------

    void error(string msg)
    {
        luaL_error(L, msg.toStringz);
        throw new LuaError(msg);
    }
    
    void error()
    {
        lua_error(L);
        throw new LuaError();
    }

    void errorif(bool cond) { if(cond) error(); }
    void errorif(bool cond, string msg) { if(cond) error(msg); }
    
    void check(int errcode) { errorif(errcode != LUA_OK); }

    //-------------------------------------------------------------------------
    // Lua Value types for transmitting them to D side
    //-------------------------------------------------------------------------

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

    //-------------------------------------------------------------------------

    bool   toboolean(int index) { return std.conv.to!bool(lua_toboolean(L, index)); }
    double tonumber(int index)  { return lua_tonumber(L, index); }
    string tostring(int index)  { return std.conv.to!(string)(lua_tostring(L, index)); }
    int    toref(int index)     { lua_pushvalue(L, index); return luaL_ref(L, LUA_REGISTRYINDEX); }
    void   unref(int id)        { luaL_unref(L, LUA_REGISTRYINDEX, id); }

    //-------------------------------------------------------------------------

    class Value
    {
        union Payload {
            bool   _bool;
            double _number;
            string _string;
            int    _id;
        }
        
        Lua     lua;
        Type    type;
        Payload payload;

        //---------------------------------------------------------------------

        this(Lua lua, int index)
        {
            Track.add(this);

            this.lua  = lua;
            this.type = lua.type(index);
            
            switch(type)
            {
                case Type.Nil:      break;
                case Type.Bool:     payload._bool   = lua.toboolean(index); break;
                case Type.Number:   payload._number = lua.tonumber(index); break;
                case Type.String:   payload._string = lua.tostring(index); break;
                case Type.Function:
                case Type.Table:    payload._id     = lua.toref(index); break;
                default:            error(); break;
            }
        }

        ~this()
        {
            Track.remove(this);
            switch(type)
            {
                case Type.Table:
                case Type.Function: lua.unref(payload._id); break;
                default: break;
            }
        }

        //---------------------------------------------------------------------

        void push()
        {
            final switch(type)
            {
                case Type.None:     return;
                case Type.Nil:      lua.push(); return;
                case Type.Bool:     lua.push(payload._bool); return;
                case Type.Number:   lua.push(payload._number); return;
                case Type.String:   lua.push(payload._string); return;
                case Type.Table:    
                case Type.Function: lua_rawgeti(lua.L, LUA_REGISTRYINDEX, payload._id); return;

                case Type.UserData:
                case Type.LightUserData:
                case Type.Thread:
                    error();
                    return;
            }
        }
        
        //---------------------------------------------------------------------

        Value opIndex(U...)(U args)
        {
            errorif(type != Type.Table, "Not a table.");
            return lua.gettable(this, args);
        }

        T get(T, U...)(U args) {
            errorif(type != Type.Table, "Not a table.");
            return cast(T)lua.gettable(this, args);
        }

        Value[] keys()
        {
            errorif(type != Type.Table, "Not a table.");
            Value[] result;
            
            lua.push(this);
            lua.push();
            while(lua_next(lua.L, -2))
            {
                result ~= lua.fetch(-2);
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

        T to(T: string)()
        {
            switch(type)
            {
                case Type.Nil:      return "null";
                case Type.Bool:     return std.conv.to!string(payload._bool);
                case Type.Number:   return std.conv.to!string(payload._number);
                case Type.String:   return std.conv.to!string(payload._string);
                default:            return std.conv.to!string(type);
            }
        }

    }
        
    //-------------------------------------------------------------------------
    // Pushing arguments to stack
    //-------------------------------------------------------------------------
    
    void push()                 { lua_pushnil(L); } 
    void push(bool b)           { lua_pushboolean(L, b); }
    void push(int  i)           { lua_pushnumber(L, i); }
    void push(float f)          { lua_pushnumber(L, f); }
    void push(double d)         { lua_pushnumber(L, d); }
    void push(char *s)          { lua_pushstring(L, s); }
    void push(char *s, int l)   { lua_pushlstring(L, s, l); }
    void push(string s)         { lua_pushlstring(L, s.ptr, s.length); }
    void push(Value v)          { v.push(); }

    //-------------------------------------------------------------------------
    // Loading Lua functions
    //-------------------------------------------------------------------------
    
    Value[] eval(string s, string from = "string")
    {
        check(luaL_loadbuffer(L, s.ptr, s.length, toStringz(from)));
        return _call();
    }

    Value[] load(string s)
    {
        return eval(blob.text(s), s);
    }

    //-------------------------------------------------------------------------
    // Stack management & inspection
    //-------------------------------------------------------------------------

    @property int  top()          { return lua_gettop(L); }
    @property void top(int index) { lua_settop(L, index); }
    void makeroom(int elems)      { lua_checkstack(L, elems); }
    
    Type type(int index = -1) { return cast(Type)lua_type(L, index); }

    void expect(int expected, int index = -1)
    {
        errorif(type(index) != expected, "Wrong type.");
    }

    //-------------------------------------------------------------------------

    Value fetch(int index = -1)
    {
        return new Value(this, index);
    }

    //-------------------------------------------------------------------------

    private Value gettable(U...)(Value root, U args)
    {
        makeroom(args.length + 1);
        if(root is null) lua_getglobal(L, "_G"); else push(root);

        expect(Type.Table);
        
        foreach(key; args)
        {
            push(key);
            lua_gettable(L, -2);
        }
        scope(exit) discard(args.length + 1);
        return fetch();
    }

    //-------------------------------------------------------------------------

    Value opIndex(U...)(U args)
    {
        return gettable(null, args);
    }

    T get(T, U...)(U args)
    {
        return cast(T)gettable(null, args);
    }

    //-------------------------------------------------------------------------

    void discard(int n) { lua_pop(L, n); }

    //-------------------------------------------------------------------------

    Value[] pop(int n = 1)
    {
        scope(exit) discard(n);
        
        Value[] ret;
        foreach(i; 1 .. n + 1) ret ~= fetch(top - n + i);
        return ret;
    }

    //-------------------------------------------------------------------------
    // Making calls to Lua functions
    //-------------------------------------------------------------------------

    private Value[] _call(int argc)
    {
        int frame = top - argc;

        expect(Type.Function, frame);
        
        lua_call(L, argc, LUA_MULTRET);
        return pop(top - frame + 1);
    }
    
    private Value[] _call()
    {
        return _call(top - 1);
    }

    //-------------------------------------------------------------------------

    void dump(string prefix)
    {
        int top = lua_gettop(L);
        writeln(prefix);
        foreach(i; 1 .. top + 1) writefln("    [%d] : %s", i, type(i));
    }    
}

