//*****************************************************************************
//
// Game engine utility module
//
//*****************************************************************************

module engine.game.util;

//-----------------------------------------------------------------------------

public import engine.util;

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
    import std.c.stdlib: exit;

    if(msg) writeln(msg);

    debug terminate();      // Terminate runtime to call destructors...
    exit(0);                // ...and exit.
}

void ERROR(string msg)
{
    quit("ERROR: " ~ msg);
}

T quitif(T)(T value, string msg = null)
{
    if(!value) quit(msg);
    return value;
}

T ERRORIF(T)(T value, string msg)
{
    if(!value) quit("ERROR: " ~ msg);
    return value;
}

