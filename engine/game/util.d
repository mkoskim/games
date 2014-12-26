//*****************************************************************************
//
// Game engine utility module
//
//*****************************************************************************

module engine.game.util;

//-----------------------------------------------------------------------------

public import engine.util;

//-----------------------------------------------------------------------------

void quit()
{
    import core.runtime: Runtime;
    import std.c.stdlib: exit;

    Runtime.terminate();	// Execute destructors, and...
    exit(0);				// ...exit
}

