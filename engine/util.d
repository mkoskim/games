//*****************************************************************************
//
// Miscellaneous utility functions for both game and render engines.
//
//*****************************************************************************

module engine.util;

//-----------------------------------------------------------------------------

//public import derelict.opengl3.gl3;
//public import derelict.sdl2.sdl;

public import std.stdio: writeln, writefln, write, writef;
public import std.string: format;
public import std.conv: to;

public import gl3n.linalg;
public import std.math: abs;

public import std.exception: enforce;
public import engine.game.util: quit, quitif, ERROR, ERRORIF;

debug public import engine.game.track: Track;

//-----------------------------------------------------------------------------

void TODO(string msg = null,
    string file = __FILE__,
    int line = __LINE__,
    string func = __FUNCTION__
) {
    //return;
    //throw new Exception("Not done yet.");
    if(msg) {
        writefln("TODO: %s (%s)", msg, func);
    } else {
        writefln("TODO: %s", func);
    }
}

//-----------------------------------------------------------------------------
//
// Manhattan distance is pretty quick to calculate, but probably nowadays
// squared distance (x*x + y*y + z*z) is as fast.
//
//-----------------------------------------------------------------------------

float manhattan(vec3 a, vec3 b)
{
    return abs(b.x-a.x) + abs(b.y-a.y) + abs(b.z-a.z);
}

//-----------------------------------------------------------------------------
//
// Sliding average is useful for various performance meters.
//
//-----------------------------------------------------------------------------

class SlidingAverage
{
    float average = 0;

    void update(float value)
    {
        const float window = 10.0;
        average += (value - average) / window;
    }
}

//-----------------------------------------------------------------------------
//
// function to simplify getting SDL attributes. Example:
//
//      writeln(_sdlattr!SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION));
//
//-----------------------------------------------------------------------------

int _sdlattr(alias func)(int arg)
{
    int result;
    func(arg, &result);
    return result;
}

string _sdlattr2str(alias func, string arg)()
{
    int result;
    func(mixin(arg), &result);
    return arg ~ " = " ~ to!string(result);
}

