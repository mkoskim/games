//*****************************************************************************
//
// Game engine utility module
//
//*****************************************************************************

module engine.game.util;

//-----------------------------------------------------------------------------

public import engine.util;

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

    if(msg) writeln(msg);

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

