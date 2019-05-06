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
import std.variant: Variant;

class State
{
    Shader shader;              // Shader to use
    Variant[string] options;    // State-specific shader options

    alias Setting = GLenum[];
    Setting[GLenum]  settings;   // OpenGL settings

    //-------------------------------------------------------------------------

    this(Shader shader) {
        debug Track.add(this);
        this.shader = shader;
    }
    
    ~this() { debug Track.remove(this); }

    //-------------------------------------------------------------------------

    State set(GLenum key, GLenum value)
    {
        settings[key] = [ value ];
        return this;
    }
    
    State set(GLenum key)   { return set(key, GL_TRUE); }    
    State unset(GLenum key) { return set(key, GL_FALSE); }
    
    State set(string key, Variant value)
    {
        options[key] = value;
        return this;
    }

    //-------------------------------------------------------------------------

    static void init(GLenum key, GLenum value) 
    {
        apply(key, [value]);
    }
    
    static void init(GLenum key)
    {
        apply(key, [GL_TRUE]);
    }

    static void init(GLenum key, GLenum arg1, GLenum arg2)
    {
        apply(key, [arg1, arg2]);
    }

    //-------------------------------------------------------------------------

    final void activate(Framebuffer target)
    {
        static State active = null;

        if(active != this)
        {
            target.bind();
            shader.activate();
            apply();

            active = this;
        }
    }

    final void activate()
    {
        activate(screen.fb);
    }

    //-------------------------------------------------------------------------

    private void apply()
    {
        shader.setOptions(options);
        foreach(key, value; settings) apply(key, value);
    }

    private static void apply(GLenum key, Setting value)
    {
        static Setting[GLenum] active;

        void enable(GLenum key, GLenum status)
        {
            if(status == GL_TRUE)
                checkgl!glEnable(key);
            else
                checkgl!glDisable(key);
        }
        
        if(key in active && active[key] == value) return ;
    
        final switch(key)
        {
            // Set polygon mode
            case GL_FRONT_AND_BACK:
                checkgl!glPolygonMode(key, value[0]);
                break;

            // Choose front face (CW / CCW) for face culling
            case GL_FRONT:
                checkgl!glFrontFace(value[0]);
                break;

            // Enable/disable face culling
            case GL_CULL_FACE_MODE:
                checkgl!glCullFace(value[0]);
                checkgl!glEnable(GL_CULL_FACE);
                break;
            
            case GL_DEPTH_FUNC:
                checkgl!glDepthFunc(value[0]);
                break;
            
            // Blend func
            case GL_BLEND:
                final switch(value.length)
                {
                    case 1: enable(key, value[0]); break;
                    case 2: checkgl!glBlendFunc(value[0], value[1]); break;
                }
                break;

            // Enable/disable options
            case GL_CULL_FACE:
            case GL_DEPTH_TEST:
            case GL_POLYGON_SMOOTH:
            case GL_LINE_SMOOTH:
            case GL_MULTISAMPLE:
                enable(key, value[0]);
                break;

            case GL_TEXTURE_COMPRESSION_HINT:
            case GL_LINE_SMOOTH_HINT:
            case GL_POLYGON_SMOOTH_HINT:
                checkgl!glHint(key, value[0]);
                break;
        }
        
        active[key] = value;
    }
}

