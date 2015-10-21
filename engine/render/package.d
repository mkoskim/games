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

//*****************************************************************************
//
// Initialization hook, called when OpenGL context has been created and
// libraries (derelict) has been reloaded. This function sets up some
// global OpenGL parameters to fit to the rendering engine.
//
//*****************************************************************************

void init()
{
    //-------------------------------------------------------------------------

    checkExtensions();

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

//*****************************************************************************
//
// Start rendering cycle. For convenience, we should have function to call
// when rendering is done... But that comes later.
//
//*****************************************************************************

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

//*****************************************************************************
//
// Extension queries: I am very interested in what versions of OpenGL I
// am using, and what extensions I have available. Currently, I am
// asking OpenGL version 2.1 context to get GLSL 120.
//
//*****************************************************************************

private void checkExtensions()
{
    writeln("OpenGL extension queries:");

    bool[string] extensions = function() {
        bool[string] lookup;
        string[] list = std.array.split(to!string(glGetString(GL_EXTENSIONS)));
        foreach(key; list) lookup[key] = true;
        return lookup;
    }();

    bool hasExtension(string key)
    {
        return key in extensions;
    }

    bool check(string extension)
    {
        bool status = hasExtension(extension);
        writefln("   [%-3s] %s", status ? "Yes" : "No", extension);
        return status;
    }

    void require(string extension)
    {
        if(!check(extension)) throw new Exception(
            format("OpenGL extension required: %s", extension)
        );
    }

    //-------------------------------------------------------------------------
    // VAO's - this is crucial.
    //-------------------------------------------------------------------------

    require("GL_ARB_vertex_array_object");

    //-------------------------------------------------------------------------
    // Do we have uniform buffers? Do we find any use for them?
    //-------------------------------------------------------------------------

    check("GL_ARB_uniform_buffer_object");
    check("GL_ARB_shader_storage_buffer_object");

    //-------------------------------------------------------------------------
    // Do we have shader subroutines?
    //-------------------------------------------------------------------------

    check("GL_ARB_shader_subroutine");

    //-------------------------------------------------------------------------
    // Do we have GL_INT_2_10_10_10_REV?
    //-------------------------------------------------------------------------

    check("GL_ARB_vertex_type_2_10_10_10_rev");

    //-------------------------------------------------------------------------
}

