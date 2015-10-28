//*****************************************************************************
//
// (Render) State: Holds OpenGL settings for rendering. This is very
// preliminary implementation which needs some serious development once
// shader subsystem is in better condition.
//
//*****************************************************************************

module engine.render.gpu.state;

import engine.render.util;
import engine.render.gpu.shader;
import engine.render.gpu.framebuffer;
import engine.game.instance;

class State
{
    Framebuffer target;         // Target buffer
    Shader shader;              // Shader to use
    Variant[string] options;    // State-specific shader options

    //-------------------------------------------------------------------------

    enum Mode { unsorted, front2back, back2front };
    Mode mode;

    void delegate() apply;  // Function to execute on switch

    //-------------------------------------------------------------------------

    this(Framebuffer fb, Shader shader, void delegate() apply, Mode mode = Mode.unsorted) {
        debug Track.add(this);
        this.target = fb;
        this.shader = shader;
        this.apply = apply;
    }
    
    this(Shader shader, void delegate() apply, Mode mode = Mode.unsorted) {
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

