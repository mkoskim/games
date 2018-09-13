//*****************************************************************************
//
// Empty project to test builds: This opens a black window, and waits
// for ESC.
//
//*****************************************************************************

import engine;
import core.thread;
import std.string: format;

//-----------------------------------------------------------------------------

void main()
{
    game.init(800, 600);

    game.Profile.enable();

    void draw()
    {
        static engine.Clock clock;

        if(clock.elapsed() > 0.5)
        {
            game.Profile.log("Perf");
            clock.start();
        }
    }

    simple.gameloop(
        50,     // FPS (limit)
        &draw,   // Drawing
        null,   // list of actors
        null    // Event processing
    );
}

