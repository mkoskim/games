//*****************************************************************************
//
// Game engine instance variables. These can be used for example to query
// window size.
//
//*****************************************************************************

module engine.game.instance;

//-----------------------------------------------------------------------------

import engine.game.input;
import engine.gpu.framebuffer;

import derelict.sdl2.sdl;
import derelict.opengl.gl;

//-----------------------------------------------------------------------------

struct SCREEN
{
    SDL_Window*   window    = null;
    SDL_GLContext glcontext = null;

    float glversion;
    float glsl;

    int width, height;
    Framebuffer fb;
}

SCREEN screen;
uint frame = 0;

//-----------------------------------------------------------------------------

Joystick controller() { return Joystick.chosen; }

