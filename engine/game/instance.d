//*****************************************************************************
//
// Game engine instance variables. These can be used for example to query
// window size.
//
//*****************************************************************************

module engine.game.instance;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;

import engine.render.gpu.framebuffer;

//-----------------------------------------------------------------------------

struct SCREEN
{
    int width, height;
    SDL_Window* window = null;
    SDL_GLContext glcontext = null;

    Framebuffer fb;
}

SCREEN screen;
uint frame = 0;

bool SDL_up = false;

