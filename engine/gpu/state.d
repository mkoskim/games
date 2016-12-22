//*****************************************************************************
//
// (Render) State: Holds OpenGL settings for rendering. This is very
// preliminary implementation which needs some serious development once
// shader subsystem is in better condition.
//
// Main drawback is apply() function. It would be better if we would keep
// track of OpenGL settings, so that we could (1) change only settings
// that need to be changed, (2) restore settings for next stage.
//
//*****************************************************************************

module engine.gpu.state;

import engine.gpu.util;
import engine.gpu.shader;
import engine.gpu.framebuffer;
import engine.game.instance;

class State
{
    Framebuffer target;         // Target buffer
    Shader shader;              // Shader to use
    Variant[string] options;    // State-specific shader options

    private void delegate() apply;

    //-------------------------------------------------------------------------

    this(Framebuffer fb, Shader shader, void delegate() apply) {
        debug Track.add(this);
        this.target = fb;
        this.shader = shader;
        this.apply = apply;
    }
    
    this(Shader shader, void delegate() apply) {
        this(screen.fb, shader, apply);
    }

    ~this() { debug Track.remove(this); }

    //-------------------------------------------------------------------------

    private static State active = null;

    final void activate()
    {
        if(active != this)
        {
            target.bind();
            shader.activate();
            shader.setOptions(options);
            apply();

            active = this;
        }
    }
}

