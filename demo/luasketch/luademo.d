//*****************************************************************************
//
// Sketching plugging LUA to game engine.
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

void main()
{
    // 1) Create interface for lua to call engine
    
    // 2) Call lua function using engine interface

    auto lua = new LuaState;
    lua.openLibs();

    auto print = lua.get!LuaFunction("print");
    print("hello, world!");
}

