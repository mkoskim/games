//*****************************************************************************
//
// Game engine instance variables. These can be used for example to query
// window size.
//
//*****************************************************************************

module engine.game.instance;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;

import engine.game.input;
import engine.gpu.framebuffer;

//-----------------------------------------------------------------------------

struct SCREEN
{
    int width, height;
    SDL_Window* window = null;

    SDL_GLContext glcontext = null;

    float glversion;
    float glsl;
    
    Framebuffer fb;
}

SCREEN screen;
uint frame = 0;

//-----------------------------------------------------------------------------

Joystick controller() { return Joystick.chosen; }

