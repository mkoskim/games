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

void init(string name, int width = 640, int height = 480)
{
    screen.width = width;
    screen.height = height;

    SDL_InitSubSystem(SDL_INIT_VIDEO);

    // Ask for OpenGL 2.1+ for GLSL version 1.20
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

    // Ask for standard 24-bit colors
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);

    // No need for destination (framebuffer) alpha layer
    SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 0);

    screen.window = SDL_CreateWindow(
        toStringz(name),
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        width, height,
        SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN
    );

    screen.glcontext = SDL_GL_CreateContext(screen.window);

    SDL_GL_SetSwapInterval(-1);

    debug {
        writefln("OpenGL: %d.%d",
            _sdlattr!SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION),
            _sdlattr!SDL_GL_GetAttribute(SDL_GL_CONTEXT_MINOR_VERSION)
        );
        writeln("- Vendor...: ", to!string(glGetString(GL_VENDOR)));
        writeln("- Renderer.: ", to!string(glGetString(GL_RENDERER)));
        writeln("- Version..: ", to!string(glGetString(GL_VERSION)));
        writeln("- GLSL.....: ", to!string(glGetString(GL_SHADING_LANGUAGE_VERSION)));
    }

    render.init();

    Joystick.init();
}

//-----------------------------------------------------------------------------

void cleantrash()
{
    import core.memory: GC;
    GC.collect();
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

class Profile
{
    auto frame  = new PerfMeter();
    auto busy   = new PerfMeter();
    auto render = new PerfMeter();
    //auto renderCPU = new PerfMeter();

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
            "FPS: %5.1f : busy %5.1f ms : logic/render/idle %5.1f%% / %5.1f%% / %5.1f%%",
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

int frame = 0;
static int framelength = 1000/60;

@property void fps(int fps)
{
    framelength = 1000 / fps;
}

//-----------------------------------------------------------------------------

void startdraw()
{
    if(Profile.timers) Profile.timers.render.start();
    render.start();
}

void waitframe()
{
    render.flush();
    SDL_GL_SwapWindow(screen.window);

    if(Profile.timers)
    {
        Profile.timers.render.stop();
        Profile.timers.busy.stop();
    }

    ticks = SDL_GetTicks();

    static uint nextframe = 0;
    if(ticks < nextframe) SDL_Delay(nextframe - ticks);	
    nextframe = SDL_GetTicks() + framelength;

    if(Profile.timers)
    {
        Profile.timers.busy.start();
        Profile.timers.frame.restart();
    }

    frame++;
}

