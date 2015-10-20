//*****************************************************************************
//
// Render core file.
//
//*****************************************************************************

module engine.render;

//-----------------------------------------------------------------------------

public import engine.render.gpu;
public import engine.render.loader.mesh;

import engine.game.instance;
import engine.render.util;

import std.stdio;
import std.string;

//-----------------------------------------------------------------------------

void init()
{
    //-------------------------------------------------------------------------
    // We are using OpenGL 2.1 for GLSL 120. Now, check that we have certain
    // crucial extensions in use.
    //-------------------------------------------------------------------------

    bool[string] extensions = function() {
        bool[string] lookup;
        string[] list = std.array.split(to!string(glGetString(GL_EXTENSIONS)));
        foreach(key; list) lookup[key] = true;
        return lookup;
    }();

    bool hasExtension(string key)
    {
        if(key in extensions) return true;
        return false;
    }

    bool check(string extension)
    {
        bool status = hasExtension(extension);
        writefln("OpenGL extension: %s - %s", extension, status ? "Yes" : "No");
        return status;
    }

    void require(string extension)
    {
        if(!check(extension)) throw new Exception(
            format("OpenGL extension required: %s", extension)
        );
    }

    require("GL_ARB_vertex_array_object");

    check("GL_ARB_uniform_buffer_object");
    check("GL_ARB_shader_storage_buffer_object");

    //require("GL_ARB_vertex_type_2_10_10_10_rev");
    //require("GL_ARB_dont_exist");

    //-------------------------------------------------------------------------

    /*
    checkgl!glEnable(GL_MULTISAMPLE);

    checkgl!glEnable(GL_LINE_SMOOTH);
    checkgl!glHint(GL_LINE_SMOOTH_HINT, GL_NICEST );

    checkgl!glEnable(GL_POLYGON_SMOOTH);
    checkgl!glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST );
    /**/

    //-------------------------------------------------------------------------

    checkgl!glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    checkgl!glPixelStorei(GL_PACK_ALIGNMENT, 1);

    //-------------------------------------------------------------------------

    screen.fb.bind();
    screen.fb.clear();
}

//-----------------------------------------------------------------------------

void start()
{
    screen.fb.bind();
    //checkgl!glViewport(0, 0, screen.width, screen.height);
    //checkgl!glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

/*
void flush()
{
    checkgl!glFinish();
}
*/

