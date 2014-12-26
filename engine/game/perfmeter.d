//*****************************************************************************
//
// Performance meter class: Uses simple sliding average
//
//*****************************************************************************

module engine.game.perfmeter;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl: SDL_GetTicks;
import engine.util;

//-----------------------------------------------------------------------------

class PerfMeter : SlidingAverage
{
    private int ticks;

    void start()   { ticks = SDL_GetTicks(); }
    void stop()    { super.update(SDL_GetTicks() - ticks); }
    void restart() { stop(); start(); }
}

//-----------------------------------------------------------------------------



