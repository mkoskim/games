//*****************************************************************************
//
// (Render) State: Holds OpenGL settings for rendering. This is very
// preliminary implementation which needs some serious development once
// shader subsystem is in better condition.
//
//*****************************************************************************

module engine.render.scene3d.state;

//-----------------------------------------------------------------------------

import engine.render.util;

import gpu = engine.render.gpu.state;
import engine.render.scene3d.shader;
import shaders = engine.render.scene3d.shader: Default3D, Flat3D;

//*****************************************************************************

class State : gpu.State
{
    //-------------------------------------------------------------------------

    this(Shader shader, void delegate() apply) {
        super(shader, apply);
    }

    //-------------------------------------------------------------------------

    static State Solid3D(Shader shader = shaders.Default3D.create())
    {
        return new State(shader, (){
            checkgl!glEnable(GL_CULL_FACE);
            checkgl!glCullFace(GL_BACK);
            checkgl!glFrontFace(GL_CCW);
            checkgl!glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            checkgl!glEnable(GL_DEPTH_TEST);
            checkgl!glDisable(GL_BLEND);
        });
    }

    static State Transparent3D(Shader shader = shaders.Default3D.create())
    {
        return new State(shader, (){
            checkgl!glEnable(GL_CULL_FACE);
            checkgl!glCullFace(GL_BACK);
            checkgl!glFrontFace(GL_CCW);
            checkgl!glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

            checkgl!glEnable(GL_DEPTH_TEST);
            checkgl!glEnable(GL_BLEND);
            checkgl!glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        });
    }
}

