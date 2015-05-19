//*****************************************************************************
//
// Render core file.
//
//*****************************************************************************

module engine.render;

public import engine.render.mesh;
public import engine.render.bound;
public import engine.render.material;
public import engine.render.texture;

public import engine.render.bone;
public import engine.render.instance;

public import engine.render.view;
public import engine.render.layer;
public import engine.render.light;

public import engine.render.shaders.base;
public import shaders = engine.render.shaders;

public import gl3n.linalg;

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

    checkgl!glHint(GL_LINE_SMOOTH_HINT, GL_NICEST );
    checkgl!glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST );

    checkgl!glEnable(GL_LINE_SMOOTH);
    checkgl!glEnable(GL_POLYGON_SMOOTH);
    /**/

    //-------------------------------------------------------------------------

    checkgl!glClearColor(0, 0, 0, 1);
    checkgl!glClearDepth(1);
}

//-----------------------------------------------------------------------------

void start()
{
    import engine.render.bone;
    Bone.clearcache();

    checkgl!glViewport(0, 0, screen.width, screen.height);
    checkgl!glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void flush()
{
    //checkgl!glFinish();
}

