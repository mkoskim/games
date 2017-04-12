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

debug public import engine.game.track: Track;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;
import derelict.opengl3.gl;

import render = engine.render;
import engine.game.util;
import engine.util;

import std.string: toStringz;

//-----------------------------------------------------------------------------

void init() { init("Unnamed"); }
void init(int width, int height) { init("Unnamed", width, height); }

void init(string name, int width = 640, int height = 480, float glversion = 3.3)
{
    screen.width = width;
    screen.height = height;

    SDL_InitSubSystem(SDL_INIT_VIDEO);

    //-------------------------------------------------------------------------
    // OpenGL context parameters
    //-------------------------------------------------------------------------

    // Ask for standard 24-bit colors
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);

    // No need for destination (framebuffer) alpha layer
    SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 0);

    //-------------------------------------------------------------------------
    // Asking specific versions, and seeing what we got. It would be good
    // to move this part to render side.
    //-------------------------------------------------------------------------

    float asked;

    void askfor(float glversion) {
        asked = glversion;
        int ver = to!int(glversion * 10);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, ver / 10);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, ver % 10);
    }

    void got(SDL_GLContext context) {
        screen.glcontext = ERRORIF(
            context,
            format(
                "OpenGL context creation failed. " ~
                "Do you have OpenGL %.1f or higher?", asked
            )
        );
        screen.glversion = 
            _sdlattr!SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION) +
            _sdlattr!SDL_GL_GetAttribute(SDL_GL_CONTEXT_MINOR_VERSION)/10.0;
        screen.glsl = to!float(to!string(glGetString(GL_SHADING_LANGUAGE_VERSION)));
    }

    askfor(glversion);

    screen.window = SDL_CreateWindow(
        toStringz(name),
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        width, height,
        SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN
    );

    got(SDL_GL_CreateContext(screen.window));

    auto glv = DerelictGL3.reload();

    screen.fb = new render.Framebuffer(0, width, height);
    screen.fb.clear();

    //SDL_GL_SetSwapInterval(0);    // Immediate
    //SDL_GL_SetSwapInterval(1);    // VSync
    SDL_GL_SetSwapInterval(-1);   // Tearing

    debug {
        writeln ("OpenGL:");
        writefln("- Context..: Version %.1f", screen.glversion);
        writefln("- Derelict.: Version %s", glv);
        writefln("- GLSL.....: %.2f", screen.glsl);
        writeln ("- Version..: ", to!string(glGetString(GL_VERSION)));
        writeln ("- Vendor...: ", to!string(glGetString(GL_VENDOR)));
        writeln ("- Renderer.: ", to!string(glGetString(GL_RENDERER)));

        //writeln("Extensions: ", to!string(glGetString(GL_EXTENSIONS)));
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

    float fps()    { return 1000 / frame.average; }
    float fpsmax() { return 1000 / busy.average; }

    static Profile timers;

    static void enable() { timers = new Profile(); }

    static string info()
    {
        if(!timers)
        {
            enable();
            return "--";
        }

        float
            frametime = timers.frame.average,
            busytime = timers.busy.average,
            rendertime = timers.render.average;

        return format(
            "FPS: %5.1f : busy %5.1f ms : %5.1f%% / %5.1f%% / %5.1f%%",
            timers.fps,
            busytime,
            100.0*(busytime-rendertime)/frametime,
            100.0*(rendertime)/frametime,
            100.0*(frametime-busytime)/frametime,
        );
    }
}

//*****************************************************************************
//
// FPS control
//
//*****************************************************************************

uint ticks = 0;

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
    static uint nextframe = 0;
    ticks = SDL_GetTicks();
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

