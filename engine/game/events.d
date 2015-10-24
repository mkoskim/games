//*****************************************************************************
//
// SDL events: This file contains functions and classes for helping with
// input events (keyboard, joystick).
//
//*****************************************************************************

module engine.game.events;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;

import engine.game.util;
import engine.game.input;

//-----------------------------------------------------------------------------
//
// Retrieving SDL events, peeking for certain events, and returning them
// to the caller.
//
//-----------------------------------------------------------------------------

int quitkey = SDLK_ESCAPE;

SDL_Event[] getevents()
{
    SDL_Event[] eventbuf;

    for(;;)
    {
        SDL_Event event;

        if(!SDL_PollEvent(&event)) break;

        switch(event.type)
        {
            default: break;

            case SDL_JOYAXISMOTION: joysticks[event.jaxis.which].update(event); break;
            case SDL_JOYBALLMOTION: joysticks[event.jball.which].update(event); break;
            case SDL_JOYHATMOTION:  joysticks[event.jhat.which].update(event); break;
            case SDL_JOYBUTTONDOWN:
            case SDL_JOYBUTTONUP:   joysticks[event.jbutton.which].update(event); break;				

            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
            case SDL_MOUSEMOTION:
                break;

            case SDL_KEYUP:
            case SDL_KEYDOWN:
                //writeln(event.key.keysym.sym);
                emulated.update(event);
                keystatus[event.key.keysym.sym] = (event.type == SDL_KEYDOWN);
                if(keydown(quitkey)) goto case SDL_QUIT;
                break;

            case SDL_QUIT:
                quit();
        }

        eventbuf ~= event;
    }

    return eventbuf;
}

