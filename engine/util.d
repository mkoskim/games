//*****************************************************************************
//
// Miscellaneous utility functions for both game and render engines.
//
//*****************************************************************************

module engine.util;

//-----------------------------------------------------------------------------

public import std.stdio: writeln, writefln, write, writef;
public import std.string: format;
public import std.conv: to;

public import std.exception: enforce;
public import engine.game.util: quit, quitif, ERROR, ERRORIF;
public import engine.math;

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
// function to simplify getting SDL attributes. Example:
//
//      writeln(_sdlattr!SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION));
//
//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;

int _sdlattr(alias func)(SDL_GLattr arg)
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

