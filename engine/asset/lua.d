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

    class LuaError : Exception {
        this(string msg) { super(msg); }
        this() { this("Lua error."); }
    }

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
    // Lua types
    //-------------------------------------------------------------------------

    enum LuaType
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
    // References to Lua objects for storing them at D side
    //-------------------------------------------------------------------------

    class LuaObject
    {
        Lua lua;
        LuaType type;
        Variant value;
        
        this(Lua lua, int index) {
            Track.add(this);

            this.lua = lua;
            this.type = lua.type(index);
            
            final switch(type)
            {
                case LuaType.None:
                case LuaType.Nil: break;
                case LuaType.Bool:   value = Variant(std.conv.to!bool(lua_toboolean(lua.L, index))); break;
                case LuaType.Number: value = Variant(lua_tonumber(lua.L, index)); break;
                case LuaType.String: value = Variant(lua_tostring(L, index)); break;
                
                case LuaType.Table:   
                case LuaType.Function:
                    value = Variant(lua.getref(index));
                    break;

                case LuaType.Thread:  
                case LuaType.UserData:
                case LuaType.LightUserData:
                    error();
            }
        }

        ~this() {
            Track.remove(this);
            switch(type)
            {
                case LuaType.Table:   
                case LuaType.Function:
                    unref(value.get!int);
                    break;
                default: break;
            }
        }        

        LuaObject[] opCall(U...)(U args)
        {
            lua.makeroom(args.length + 1);
            lua.push(this);
            foreach(arg; args) lua.push(arg);
            return lua._call();
        }
        
        LuaObject opIndex(U...)(U args)
        {
            return lua.gettable(this, args);
        }
    }

    //-------------------------------------------------------------------------
    // Pushing arguments to stack
    //-------------------------------------------------------------------------
    
    void push()                { lua_pushnil(L); } 
    void push(bool b)          { lua_pushboolean(L, b); }
    void push(int  i)          { lua_pushnumber(L, i); }
    void push(float f)         { lua_pushnumber(L, f); }
    void push(double d)        { lua_pushnumber(L, d); }
    void push(char *s)         { lua_pushstring(L, s); }
    void push(char *s, int l)  { lua_pushlstring(L, s, l); }
    void push(string s)        { lua_pushlstring(L, s.ptr, s.length); }

    void push(LuaObject o)     
    { 
        final switch(o.type)
        {
            case LuaType.None:   break;
            case LuaType.Nil:    push(); break;
            case LuaType.Bool:   push(o.value.get!bool); break;
            case LuaType.Number: push(o.value.get!double); break;
            case LuaType.String: push(o.value.get!string); break;
            
            case LuaType.Table:   
            case LuaType.Function:
                lua_rawgeti(L, LUA_REGISTRYINDEX, o.value.get!int);
                break;

            case LuaType.Thread:  
            case LuaType.UserData:
            case LuaType.LightUserData:
                error();
        }
    }

    //-------------------------------------------------------------------------
    // Loading Lua functions
    //-------------------------------------------------------------------------
    
    LuaObject[] eval(string s, string from = "string")
    {
        check(luaL_loadbuffer(L, s.ptr, s.length, toStringz(from)));
        return _call();
    }

    LuaObject[] load(string s)
    {
        return eval(blob.text(s), s);
    }

    //-------------------------------------------------------------------------
    // Stack management & inspection
    //-------------------------------------------------------------------------

    @property int  top()          { return lua_gettop(L); }
    @property void top(int index) { lua_settop(L, index); }
    void makeroom(int elems)      { lua_checkstack(L, elems); }
    
    LuaType type(int index = -1) { return cast(LuaType)lua_type(L, index); }

    void expect(int expected, int index = -1)
    {
        errorif(type(index) != expected, "Wrong type.");
    }

    //-------------------------------------------------------------------------

    private int getref(int index)
    {
        lua_pushvalue(L, index);
        return luaL_ref(L, LUA_REGISTRYINDEX);
    }

    private int unref(int refno)
    {
        luaL_unref(L, LUA_REGISTRYINDEX, refno);
        return LUA_REFNIL;
    }

    //-------------------------------------------------------------------------


    LuaObject fetch(int index = -1)
    {
        return new LuaObject(this, index);
    }

    //-------------------------------------------------------------------------

    private LuaObject gettable(U...)(LuaObject root, U args)
    {
        makeroom(args.length + 1);
        if(root is null) lua_getglobal(L, "_G"); else push(root);

        foreach(key; args)
        {
            push(key);
            lua_gettable(L, -2);
        }
        scope(exit) discard(args.length + 1);
        return fetch();
    }

    //-------------------------------------------------------------------------

    LuaObject opIndex(U...)(U args)
    {
        return gettable(null, args);
    }

    //-------------------------------------------------------------------------

    void discard(int n) { lua_pop(L, n); }

    //-------------------------------------------------------------------------

    LuaObject[] pop(int n = 1)
    {
        scope(exit) discard(n);
        
        LuaObject[] ret;
        foreach(i; 1 .. n + 1) ret ~= fetch(top - n + i);
        return ret;
    }

    //-------------------------------------------------------------------------
    // Making calls to Lua functions
    //-------------------------------------------------------------------------

    private LuaObject[] _call(int argc)
    {
        int frame = top - argc;

        errorif(type(frame) != LuaType.Function, "Not a function.");
        
        lua_call(L, argc, LUA_MULTRET);
        return pop(top - frame + 1);
    }
    
    private LuaObject[] _call()
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

