//*****************************************************************************
//
// Empty project to test builds: This opens a black window, and waits
// for ESC.
//
//*****************************************************************************

import engine;
import vfs = engine.asset.vfs;

//-----------------------------------------------------------------------------

void main()
{
    game.init(800, 600);

    simple.gameloop(
        50,     // FPS (limit)
        null,   // Drawing
        null,   // list of actors
        null    // Event processing
    );
}

