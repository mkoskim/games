//*****************************************************************************
//
// SDL events
//
//*****************************************************************************

module engine.game.events;

//-----------------------------------------------------------------------------

import derelict.sdl2.sdl;

import engine.game.util;

//-----------------------------------------------------------------------------
// Keyboard status
//-----------------------------------------------------------------------------

bool[uint] keystatus;

bool keydown(uint keycode) { return keycode in keystatus && keystatus[keycode]; }
bool keyup(uint keycode)   { return !keydown(keycode); }

//-----------------------------------------------------------------------------
// Definitions for XBox 360 controller
//-----------------------------------------------------------------------------

struct JOY
{
	//-------------------------------------------------------------------------

	enum AXIS : uint {
		LX = 0, LY, LT,		// Left X & Y, and left trigger
		RX = 3, RY, RT		// Right X & Y, and right trigger
	}
	
	//-------------------------------------------------------------------------

	enum BTN : uint {
		//---------------------------------------------------------------------
		// Normal buttons
		//---------------------------------------------------------------------

		A = 0, B, X, Y,
		LB = 4, RB,
		BACK = 6, START, GUIDE,
		LS = 9, RS = 10,
		
		//---------------------------------------------------------------------
		// Emulated "axis buttons": Each axis has two virtual buttons: left/up
		// and right/down. Keep the order the same as the order of axes.
		//---------------------------------------------------------------------

		LS_LEFT, LS_RIGHT,		// Left stick X
		LS_UP, LS_DOWN,			// Left stick Y
		LT_FREE, LT,			// Left trigger
		
		RS_LEFT, RS_RIGHT,		// Right stick X
		RS_UP, RS_DOWN,			// Right stick Y
		RT_FREE, RT,			// Right trigger

		//---------------------------------------------------------------------
		// Emulated "hat buttons": Each hat has four virtual buttons: left,
		// right, up and down. Keep the order the same direction masks are
		// in button emulation code.
		//---------------------------------------------------------------------

		DPAD_LEFT, DPAD_RIGHT,
		DPAD_UP, DPAD_DOWN,
	}
}
	
//-----------------------------------------------------------------------------
// Definitions for XBox 360 controller
//-----------------------------------------------------------------------------

class Joystick
{

	//-------------------------------------------------------------------------
	
	float[] axes;
	byte[]  buttons;
	byte[]  hats;
	
	//-------------------------------------------------------------------------

	private static const float AXIS_TRESHOLD = 0.05;
	private uint AXISBTN_FIRST;
	private uint HATBTN_FIRST;
	
	//-------------------------------------------------------------------------
	
	void update(SDL_Event *event)
	{
		void emulate(ubyte btn, uint type)
		{
			SDL_Event ev;
			ev.type = type;
			ev.jbutton.button = btn;
			ev.jbutton.state = (type == SDL_JOYBUTTONDOWN) ? 1 : 0;
			SDL_PushEvent(&ev);
		}

		switch(event.type)
		{
			default: break;

			//-----------------------------------------------------------------
			// Update button status
			//-----------------------------------------------------------------
			
			case SDL_JOYBUTTONDOWN:
			case SDL_JOYBUTTONUP:
				buttons[event.jbutton.button] = event.jbutton.state;
				break;

			//-----------------------------------------------------------------
			// Analog triggers/sticks. Scale axis value between -1 ... 1,
			// and emulate two buttons (at positive and negative ends),
			// with hysteresis.
			//-----------------------------------------------------------------
			
			case SDL_JOYAXISMOTION: {
				float value = (event.jaxis.value + 0.5) / 32768.0;
				if(fabs(value) < AXIS_TRESHOLD) value = 0.0;
				axes[event.jaxis.axis] = value;
				
				//-------------------------------------------------------------
				// Emulated button at negative range
				//-------------------------------------------------------------
				
				ubyte btn = cast(ubyte)(AXISBTN_FIRST + event.jaxis.axis*2);

				if(!buttons[btn] && value < -0.66) {
					emulate(btn, SDL_JOYBUTTONDOWN);
				}
				else if(buttons[btn] && value > -0.33) {
					emulate(btn, SDL_JOYBUTTONUP);
				}
						
				//-------------------------------------------------------------
				// Emulated button at positive range
				//-------------------------------------------------------------
				
				btn = cast(ubyte)(AXISBTN_FIRST + event.jaxis.axis*2 + 1);
				if(!buttons[btn] && value > 0.66) {
					emulate(btn, SDL_JOYBUTTONDOWN);
				}
				else if(buttons[btn] && value < 0.33) {
					emulate(btn, SDL_JOYBUTTONUP);
				}				
			}
			break;
			
			//-----------------------------------------------------------------
			// Hats (digital directional pads)
			//-----------------------------------------------------------------

			case SDL_JOYHATMOTION:
			{
				static ubyte[] masks = [
					SDL_HAT_LEFT,
					SDL_HAT_RIGHT,
					SDL_HAT_UP,
					SDL_HAT_DOWN,
				];
				
				ubyte prev = hats[event.jhat.hat];
				ubyte current = event.jhat.value;

				ubyte rising  =  current & ~prev;
				ubyte falling = ~current &  prev;
				
				ubyte btn = cast(ubyte)(HATBTN_FIRST + event.jhat.hat*4);

				foreach(i, mask; masks)
				{
					if(rising & mask)
						emulate(cast(ubyte)(btn + i), SDL_JOYBUTTONDOWN);
					else if(falling & mask)
						emulate(cast(ubyte)(btn + i), SDL_JOYBUTTONUP);
				}
				
				hats[event.jhat.hat] = current;
			}
			break;

			//-----------------------------------------------------------------
			// Trackballs (not yet implemented)
			//-----------------------------------------------------------------

			case SDL_JOYBALLMOTION:
				break;
		}
	}

	//-------------------------------------------------------------------------
	
	private SDL_Joystick *stick;	// SDL Joystick
	private SDL_Haptic *ffb;		// SDL Force Feedback
	
	private this(int num)
	{
		stick = SDL_JoystickOpen(num);
		if(SDL_JoystickIsHaptic(stick) == 1)
		{
			ffb = SDL_HapticOpenFromJoystick(stick);
		}
		else
		{
			ffb = null;
		}

		axes = new float[SDL_JoystickNumAxes(stick)];
		hats = new byte[SDL_JoystickNumHats(stick)];
		buttons = new byte[
			SDL_JoystickNumButtons(stick)	// Normal buttons
			+ 2*axes.length					// Emulated axis buttons
			+ 4*hats.length					// Emulated hat buttons
		];

		AXISBTN_FIRST = SDL_JoystickNumButtons(stick);
		HATBTN_FIRST  = AXISBTN_FIRST + cast(uint)axes.length*2;

		SDL_JoystickUpdate(stick);

		foreach(i; 0 .. axes.length)    axes[i] = SDL_JoystickGetAxis(stick, cast(int)i);
		foreach(i; 0 .. buttons.length) buttons[i] = SDL_JoystickGetButton(stick, cast(int)i);
		foreach(i; 0 .. hats.length)    hats[i] = SDL_JoystickGetHat(stick, cast(int)i);

		SDL_JoystickEventState(SDL_ENABLE);

		writefln("Joystick#%d: %s (haptic: %s)",
			num,
			to!string(SDL_JoystickName(stick)),
			ffb ? "yes" : "no"
		);
	}

	~this()
	{
		SDL_JoystickClose(stick);
		SDL_HapticClose(ffb);
	}

	//-------------------------------------------------------------------------
	
	package static void init()
	{
    	SDL_InitSubSystem(SDL_INIT_JOYSTICK);

		int num = SDL_NumJoysticks();
	
		foreach(i; 0 .. num)
		{
			joysticks ~= new Joystick(i);		
		}
	}
}

Joystick joysticks[];

//-----------------------------------------------------------------------------

int quitkey = SDLK_ESCAPE;

SDL_Event*[] getevents()
{
	SDL_Event* eventbuf[];
	
	for(;;)
	{
		SDL_Event *event = new SDL_Event();
		
    	if(!SDL_PollEvent(event)) break;

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
		    	keystatus[event.key.keysym.sym] = false;
		    	break;

		    case SDL_KEYDOWN:
		    	keystatus[event.key.keysym.sym] = true;
		    	if(event.key.keysym.sym == quitkey) goto case SDL_QUIT;
		    	break;

		    case SDL_QUIT:
		    	quit();
		}
		
		eventbuf ~= event;
	}
	
	return eventbuf;
}

