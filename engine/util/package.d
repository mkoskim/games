//*****************************************************************************
//
// Miscellaneous utility functions for both game and render engines.
//
//*****************************************************************************

module engine.util;

//-----------------------------------------------------------------------------

public
{
    import std.string: format;
    import std.conv: to;

    import std.exception: enforce;
    import engine.math;

    import engine.util.clock: Clock;
    import engine.util.timer: Timer;
    import engine.util.lua;
    import vfs = engine.util.vfs;

    debug import engine.util.track: Track;
    import engine.util.logger: Log, Watch;
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

//-----------------------------------------------------------------------------

void rungc() {
    import core.memory: GC;
    GC.collect();
}

//-----------------------------------------------------------------------------
//
// Quitting the game. Terminating runtime before exit() is optional feature
// to run destructors and see that it happens without errors (which may
// indicate more severe malfunctions in code).
// 
//-----------------------------------------------------------------------------

private void terminate()
{
    import core.runtime: Runtime;

    Runtime.terminate();
}

void quit(string msg = null)
{
    import core.stdc.stdlib: exit;

    if(msg) Log << msg;

    //rungc();
    //debug terminate();    // Terminate runtime to call destructors...
    exit(0);                // ...and exit.
}

void quitif(bool value, lazy string msg = null)
{
    if(value) quit(msg());
}

//-----------------------------------------------------------------------------

void ERROR(string msg, string file = __FILE__, int line = __LINE__, string func = __FUNCTION__)
{
    throw new Exception(format("ERROR: %s@%s:%d: %s", func, file, line, msg));
}

//-----------------------------------------------------------------------------
// Use lazy msg parameter, because it may containg calls to
// functions only working if the error happened.
//-----------------------------------------------------------------------------

void ERRORIF(bool value, lazy string msg, string file = __FILE__, int line = __LINE__, string func = __FUNCTION__)
{
    if(value) ERROR(msg(), file, line, func);
}

