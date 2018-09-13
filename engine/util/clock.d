//*****************************************************************************
//
// Clock() helps measuring time between events.
//
//*****************************************************************************

module engine.util.clock;

import derelict.sdl2.sdl: SDL_GetTicks;

struct Clock
{
    private int ticks;

    void  start()   { ticks = SDL_GetTicks(); }
    float elapsed() { return (SDL_GetTicks() - ticks) * 1e-3; }
}
