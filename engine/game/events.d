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

        void send2joystick(int joy, SDL_Event ev) {
            //writeln("Joystick event: ", joy);
            if(joy in controllers) controllers[joy].update(event);
        }

        switch(event.type)
        {
            default: break;

            case SDL_JOYDEVICEADDED:   Joystick.add(event.jdevice.which); break;
            case SDL_JOYDEVICEREMOVED: Joystick.remove(event.jdevice.which); break;
            
            case SDL_JOYAXISMOTION: send2joystick(event.jaxis.which, event); break;
            case SDL_JOYBALLMOTION: send2joystick(event.jball.which, event); break;
            case SDL_JOYHATMOTION:  send2joystick(event.jhat.which, event); break;
            case SDL_JOYBUTTONDOWN:
            case SDL_JOYBUTTONUP:   send2joystick(event.jbutton.which, event); break;				

            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
            case SDL_MOUSEMOTION:
                break;

            case SDL_KEYUP:
            case SDL_KEYDOWN:
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

