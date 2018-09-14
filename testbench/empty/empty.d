//*****************************************************************************
//
// Empty project to test builds: This opens a black window, and waits
// for ESC.
//
//*****************************************************************************

import engine;

//-----------------------------------------------------------------------------

void main()
{
    game.init(800, 600);

    game.Profile.enable();

    void report()
    {
        game.Profile.log("Perf");
        
        game.frametimer.add(0.5, &report);
    }

    report();
    
    simple.gameloop(
        50,     // FPS (limit)
        null,   // Drawing
        null,   // list of actors
        null    // Event processing
    );
}

