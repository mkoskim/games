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

    void draw()
    {
        static int ticks = 0;
        if(SDL_GetTicks() - ticks < 500) return;
        game.Profile.log("Perf");
        ticks = SDL_GetTicks();
    }

    simple.gameloop(
        50,     // FPS (limit)
        &draw,   // Drawing
        null,   // list of actors
        null    // Event processing
    );
}

