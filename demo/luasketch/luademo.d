//*****************************************************************************
//
// Sketching plugging LUA to game engine.
//
// NOTE: https://github.com/JakobOvrum/LuaD/issues/93
//
//      I might need to postpone this development until the
//      bug is found & fixed. Otherwise I can't know if I made it
//      right or wrong.
//
//*****************************************************************************

import engine;

//*****************************************************************************
//
// There is a desperate need for asset loader scripts. Assets - textures,
// meshes - come in various formats, and using them can be manual work. What
// I would like to have, is scripts in resource folders which can set up the
// asset correctly for the engine.
//
// I don't have the luxury to demand my game resources in specific formats
// and layouts, instead I gather them from multiple sources with variating
// quality, structure and setup.
//
// An example here is skybox. Skybox is formed from six textures. Creating
// a skybox requires you to type these six textures all over again, and
// always in correct order. So, instead of that, would it be great to write
// correct sequence just once, and then have script to do the dirty work?
//
//*****************************************************************************

//*****************************************************************************
//
// How I want it to work (sketch):
//
//      main.d:
//
//          ...
//          auto skybox = SkyBox("path/to/skybox1.lua");
//
//      skybox1.lua:
//
//          Cubemap cubemap = Cubemap("img1", "img2", ...);
//          return SkyBox(cubemap);
//
//*****************************************************************************

import luad.all;
import std.stdio;

//-----------------------------------------------------------------------------
// We need to limit the access of the scripts, and redirect the functions...
// For example, LUA dofile(filename) needs to be go through BLOB management.
// We don't want scripts to have direct access to filesystem.
//-----------------------------------------------------------------------------

import core.vararg;

class LuaBox : LuaState
{
    //-------------------------------------------------------------------------

    this() {
        super();
        openLibs();

        {
            auto blob = newTable();
            this["blob"] = blob;

            blob["loadtext"]  = (string filename) { return cast(string)(.blob.extract(filename)); };
        }
    }

    //-------------------------------------------------------------------------

    LuaFunction func(string filename, string funcname) {
        doString(blob.loadtext("data/test.lua"));
        return get!LuaFunction(funcname);
    }

    /*
    LuaObject[] run(string filename, string funcname = null, ...)
    {
        doString(blob.loadtext("data/test.lua"));
        if(funcname) {
            auto func = get!LuaFunction(funcname);
            return func();
        }
        return [];
    }
    */
}

//-----------------------------------------------------------------------------
// Creating interface for LUA to access D functions
//-----------------------------------------------------------------------------

void main()
{
    auto lua = new LuaBox;

    writeln(lua.func("data/test.lua", "loadmessage")());

    /*
    auto result = lua.run("data/test.lua");
    writeln(result);
    */

    writeln("Done.");
}

