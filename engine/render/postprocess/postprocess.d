//*****************************************************************************
//
// Framebuffer postprocessing.
//
//*****************************************************************************

module engine.render.postprocess.postprocess;

import engine.render.util;

import engine.render.gpu.shader;
import engine.render.gpu.framebuffer;
import engine.render.gpu.state;

class PostProcess
{
    Framebuffer source;
    Shader shader;
    State state;

    this(string filename, Framebuffer target, Framebuffer source)
    {
        this.shader = new Shader(filename);
        this.state = new State(target, this.shader);
        this.source = source;
    }
}

