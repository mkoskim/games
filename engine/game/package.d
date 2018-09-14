//*****************************************************************************
//
// Package for game modules
//
//*****************************************************************************

module engine.game;

//-----------------------------------------------------------------------------

public import engine.game.instance;
public import engine.game.fiber;
public import engine.game.perfmeter;
public import engine.game.events;
public import engine.game.input;
public import engine.game.util: quit, rungc;

//debug public import engine.util.track: Track;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;
import derelict.opengl;

import render = engine.render;
import engine.game.util;
import engine.util;

import std.string: toStringz;
import std.array: split;

//-----------------------------------------------------------------------------

void init() { init("Unnamed"); }
void init(int width, int height) { init("Unnamed", width, height); }

void init(string name, int width = 640, int height = 480, int[2] askfor = [3, 3])
{
    screen.width = width;
    screen.height = height;

    SDL_InitSubSystem(SDL_INIT_VIDEO);

    //-------------------------------------------------------------------------
    // OpenGL context parameters
    //-------------------------------------------------------------------------

    // Ask for specified OpenGL version
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, askfor[0]);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, askfor[1]);
    
    // Ask for standard 24-bit colors
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);

    // No need for destination (framebuffer) alpha layer
    SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 0);

    //-------------------------------------------------------------------------
    // Try to create context
    //-------------------------------------------------------------------------

    screen.window = SDL_CreateWindow(
        toStringz(name),
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        width, height,
        SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN
    );

    screen.glcontext = ERRORIF(
        SDL_GL_CreateContext(screen.window),
        format(
            "OpenGL context creation failed. " ~
            "Do you have OpenGL %d.%d or higher?", askfor[0], askfor[1]
        )
    );

    DerelictGL3.reload();

    //-------------------------------------------------------------------------
    // Got it - fill in info
    //-------------------------------------------------------------------------

    screen.fb = new render.Framebuffer(0, width, height);

    screen.glversion =
        _sdlattr!SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION) + 
        _sdlattr!SDL_GL_GetAttribute(SDL_GL_CONTEXT_MINOR_VERSION) * 0.1
    ;
    screen.glsl = to!float(
        to!string(glGetString(GL_SHADING_LANGUAGE_VERSION)).split()[0]
    );

    //SDL_GL_SetSwapInterval(0);    // Immediate
    //SDL_GL_SetSwapInterval(1);    // VSync
    SDL_GL_SetSwapInterval(-1);   // Tearing

    debug {
        //Log("OpenGL")
        Log("GLinfo") 
            << format("Context..: %.1f", screen.glversion)
            << format("GLSL.....: %.2f", screen.glsl)
            << format("Derelict.: %s", to!string(DerelictGL3.loadedVersion()))
        ;
/*
        trace("OpenGL", format("Driver...: %s", to!string(glGetString(GL_RENDERER))));
        trace("OpenGL", format("Vendor...: %s", to!string(glGetString(GL_VENDOR))));
        trace("OpenGL", format("Version..: %s", to!string(glGetString(GL_VERSION))));
        trace("OpenGL", format("GLSL.....: %s", to!string(glGetString(GL_SHADING_LANGUAGE_VERSION))));
*/

        //Watch
        Log << format("%s = %s", "A", "B");
        Watch.update("A", "B");

        Log("Perf") << "X = Y";
        Watch("Perf").update("X", "Y");
        Watch("Perf").update("X", "Z");
    }

    render.init();
    Joystick.init();    
}

//*****************************************************************************
//
// Basic performance measurement
//
//      frametime:  Length of the frame cycle
//
//      busytime:   Time between SDL_Delay() calls
//
//      rendertime: Time from render start to return from buffer swapping.
//                  This measurement does not tell much about CPU/GPU load.
//
//      idletime:   Time used in SDL_Delay()
//
//*****************************************************************************

import engine.math: SlidingAverage;

class Profile
{
    auto frame   = new PerfMeter();
    auto busy    = new PerfMeter();
    auto render  = new PerfMeter();
    auto calls   = new SlidingAverage();

    float fps()    { return 1 / frame.average; }
    float fpsmax() { return 1 / busy.average; }

    static Profile timers;

    static void enable() { timers = new Profile(); }

    static void log(string group)
    {
        if(!timers)
        {
            enable();
            return;
        }

        float
            frametime = timers.frame.average,
            busytime = timers.busy.average,
            rendertime = timers.render.average;

        Watch(group)
            .update("FPS", format("%5.1f", timers.fps))
            .update("Frame", format("%5.1f ms", 1000 * frametime))
            .update("Busy", format("%5.1f ms", 1000 * busytime))
            .update("Render", format("%5.1f ms", 1000 * rendertime))
            //.update("CPU", format("%5.1f %%", 100.0*(busytime-rendertime)/frametime))
            //.update("GPU", format("%5.1f %%", 100.0*(rendertime)/frametime))
            //.update("Idle", format("%5.1f %%", 100.0*(frametime-busytime)/frametime))
        ;
    }
}

//*****************************************************************************
//
// FPS control
//
//*****************************************************************************

private int framelength = 1000/50;

@property void fps(int fps)
{
    framelength = 1000 / fps;
}

//-----------------------------------------------------------------------------

import engine.gpu.util: glcalls;

void startdraw()
{
    if(Profile.timers) Profile.timers.render.start();
    glcalls = 0;
    render.start();
}

Timer.Queue frametimer;

void waitframe()
{
    SDL_GL_SwapWindow(screen.window);

    if(Profile.timers)
    {
        Profile.timers.render.stop();
        Profile.timers.busy.stop();
        Profile.timers.calls.update(glcalls);
    }

    /* Here, we could try to do something useful instead just sleeping. We
     * may implement some sort of idle handler.
     */
    
    frametimer.tick(framelength * 1e-3);
    
    static uint nextframe = 0;
    uint ticks = SDL_GetTicks();
    if(nextframe > ticks)
    {
        SDL_Delay(nextframe - ticks);
        ticks = nextframe;
    }
    nextframe = ticks + framelength;

    if(Profile.timers)
    {
        Profile.timers.busy.start();
        Profile.timers.frame.restart();
    }

    frame++;
}

