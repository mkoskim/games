//*****************************************************************************
//
// Miscellaneous utility functions for both game and render engines.
//
//*****************************************************************************

module engine.util;

//-----------------------------------------------------------------------------

public import std.string: format;
public import std.conv: to;

public import std.exception: enforce;
public import engine.math;

debug public import engine.util.track: Track;
public import engine.util.logger: Log, Watch;

//-----------------------------------------------------------------------------

void TODO(string msg = null,
    string file = __FILE__,
    int line = __LINE__,
    string func = __FUNCTION__
) {
    //return;
    //throw new Exception("Not done yet.");
    if(msg) {
        //trace("TODO", format("%s (%s)", msg, func));
    } else {
        //trace("TODO", format("%s", func));
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

    //if(msg) trace(msg);

    rungc();
    //debug terminate();    // Terminate runtime to call destructors...
    exit(0);                // ...and exit.
}

T quitif(T)(T value, string msg = null)
{
    if(!value) quit(msg);
    return value;
}

//-----------------------------------------------------------------------------

void ERROR(string msg, string file = __FILE__, int line = __LINE__, string func = __FUNCTION__)
{
    quit(format("ERROR: %s@%s:%d: %s", func, file, line, msg));
}

T ERRORIF(T)(T value, string msg, string file = __FILE__, int line = __LINE__, string func = __FUNCTION__)
{
    if(!value) ERROR(msg, file, line, func);
    return value;
}

