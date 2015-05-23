//*****************************************************************************
//
// Render core file.
//
//*****************************************************************************

module engine.render;

public {
    import engine.render.transform;
    import engine.render.mesh;
    import engine.render.bound;
    import engine.render.material;
    import engine.render.texture;
    import engine.render.model;
    import engine.render.node;

    import engine.render.view;
    import engine.render.light;

    import engine.render.batch;
    import engine.render.layer;

    import engine.render.state;
    import engine.render.shaders.base;
    import shaders = engine.render.shaders;

    import gl3n.linalg;
}

//-----------------------------------------------------------------------------

import engine.game.instance;
import engine.render.util;

import std.stdio;

//-----------------------------------------------------------------------------

void init()
{
    auto glv = DerelictGL3.reload();

    //debug writefln("OpenGL: Version %s", glv);

    //-------------------------------------------------------------------------

    /*
    checkgl!glEnable(GL_MULTISAMPLE);

    checkgl!glEnable(GL_LINE_SMOOTH);
    checkgl!glHint(GL_LINE_SMOOTH_HINT, GL_NICEST );

    checkgl!glEnable(GL_POLYGON_SMOOTH);
    checkgl!glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST );
    /**/

    //-------------------------------------------------------------------------

    checkgl!glClearColor(0, 0, 0, 1);
    checkgl!glClearDepth(1);
}

//-----------------------------------------------------------------------------

void start()
{
    checkgl!glViewport(0, 0, screen.width, screen.height);
    checkgl!glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

/*
void flush()
{
    checkgl!glFinish();
}
*/

