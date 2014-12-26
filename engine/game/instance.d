//*****************************************************************************
//
// Game engine instance variables
//
//*****************************************************************************

module engine.game.instance;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;

//-----------------------------------------------------------------------------

struct SCREEN
{
    int width, height;
    SDL_Window* window = null;
    SDL_GLContext glcontext = null;
}

SCREEN screen;

