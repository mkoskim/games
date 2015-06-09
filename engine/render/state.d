//*****************************************************************************
//
// (Render) State: Holds OpenGL settings for rendering.
//
//*****************************************************************************

module engine.render.state;

//-----------------------------------------------------------------------------

import engine.render.util;

import engine.render.shaders.base;
import shaders = engine.render.shaders.defaults;

//*****************************************************************************

class State
{
    Shader shader;
    void delegate() apply;

    //-------------------------------------------------------------------------

    this(Shader shader, void delegate() apply) {
        this.apply = apply;
        this.shader = shader;
    }
    
    //-------------------------------------------------------------------------
    
    static State Default2D(Shader shader = shaders.Default2D.create())
    {
        return new State(shader, (){
            checkgl!glDisable(GL_CULL_FACE);
            checkgl!glDisable(GL_DEPTH_TEST);
            checkgl!glEnable(GL_BLEND);
            checkgl!glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        });
    }
    
    static State Solid3D(Shader shader = shaders.Default3D.create())
    {
        return new State(shader, (){
            checkgl!glEnable(GL_CULL_FACE);
            checkgl!glCullFace(GL_BACK);
            checkgl!glFrontFace(GL_CCW);
            checkgl!glPolygonMode(GL_FRONT, GL_FILL);
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
            checkgl!glPolygonMode(GL_FRONT, GL_FILL);
            
            checkgl!glEnable(GL_DEPTH_TEST);
            checkgl!glEnable(GL_BLEND);
            checkgl!glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        });
    }
    
    //-------------------------------------------------------------------------
    
    private static State active = null;
        
    final void activate()
    {
        if(active != this)
        {
            shader.activate();
            apply();
            active = this;
        }
    }
}

