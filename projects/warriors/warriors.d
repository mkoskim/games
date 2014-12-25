//*****************************************************************************
//
// Warriors is a fighting game in a fantasy world.
//
//*****************************************************************************

import std.stdio;
import std.string;
import std.array;

import engine;

//-----------------------------------------------------------------------------
//
// Main focus ATM: Design the UI for fighting.
//
//-----------------------------------------------------------------------------

//*****************************************************************************
//
// SKILLS:
//
// When skill is triggered:
// - Cooldown starts
// - Animation starts: animation prevents triggering other skills
//
// Note:
//
//	- Skills share cooldown timer
//
//*****************************************************************************

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

class CooldownTimer
{
	uint end;
	uint duration;
		
	this() {
		duration = 0;
		end = 0;
	}

	void fire(uint t)	{ end = game.ticks + t; duration = t; }
	bool running() 		{ return game.ticks < end; }	
	uint left()			{ return running() ? end - game.ticks : 0; }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

class Skill {
	string name;
	
	CooldownTimer* cooldown;

	uint animtime;		// How long (ms) it takes to perform this?
	uint hotspot;		// At which point (ms) effect is applied?

	this(string name_, CooldownTimer *cooldown_) {
		name = name_;
		cooldown = cooldown_;
	}

	this(string name_, Skill *skill) {
		this(name_, skill.cooldown);
	}
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

class Player : game.Fiber
{

	this() { super(&run); }

	//-------------------------------------------------------------------------
	// Events dispatched to player
	//-------------------------------------------------------------------------

	private SDL_Event* events[];

	private SDL_Event* getevent() {
		while(events.empty()) nextframe();
		auto event = events.back();
		events.popBack();
		return event;
	}

	void addevent(SDL_Event *event)
	{
		events ~= event;
	}

	//-------------------------------------------------------------------------
	//
	// Exec choosing from quick slot associated to a button. Releasing a
	// button fires the chosen skill. 'X' cancels action. Opposite trigger
	// moves in the menu.
	//
	// Holding key a moment initiates skill charging.
	//
	//-------------------------------------------------------------------------

	void execslot(uint button)
	{
		writeln("Slot: ", button);

		for(;;)
		{
			SDL_Event* event = getevent();
			
			switch(event.type)
			{
				default: break;

				//-------------------------------------------------------------
				// Pressing a button
				//-------------------------------------------------------------
				
				case SDL_JOYBUTTONDOWN:
					switch(event.jbutton.button)
					{
						//-----------------------------------------------------
						// By default, button presses cancel the selection,
						// and the press is reprocessed in the main state,
						// except 'X' which is plain cancel.
						//-----------------------------------------------------
						
						default:
							addevent(event);
							goto case game.JOY.BTN.X;

						case game.JOY.BTN.X:
							writeln("Cancel: ", button);
							return;

						//-----------------------------------------------------
						// Keys to choose and use skills
						//-----------------------------------------------------

						case game.JOY.BTN.LT:
						case game.JOY.BTN.RT:
							writeln("Next: ", button);
							break;
							
						//-----------------------------------------------------
						// Triggers' up 'presses' are silently ignored
						//-----------------------------------------------------

						case game.JOY.BTN.LT_FREE:
						case game.JOY.BTN.RT_FREE:
							break;
					}
					break;

				//-------------------------------------------------------------
				// Releasing a button
				//-------------------------------------------------------------
				
				case SDL_JOYBUTTONUP:
					if(event.jbutton.button == button)
					{
						writeln("Fire: ", button);
						return;
					}
					break;
			}
		}
	}

	//-------------------------------------------------------------------------
	// Main combat state.
	//-------------------------------------------------------------------------

	void run() {
		for(;;) {
			SDL_Event* event = getevent();
			
			switch(event.type)
			{
				default: break;

				//-------------------------------------------------------------
				// Pressing a button
				//-------------------------------------------------------------
				
				case SDL_JOYBUTTONDOWN: switch(event.jbutton.button)
				{
					default: break;

					//---------------------------------------------------------
					// Choosing from quickslots
					//---------------------------------------------------------					

					case game.JOY.BTN.LT:
					case game.JOY.BTN.LB:
					case game.JOY.BTN.RT:
					case game.JOY.BTN.RB:
						execslot(event.jbutton.button);
						break;

					//---------------------------------------------------------
					// Other buttons
					//---------------------------------------------------------					

					case game.JOY.BTN.A:
					case game.JOY.BTN.B:
					case game.JOY.BTN.X:
					case game.JOY.BTN.Y:
						writeln("Pressed: ", event.jbutton.button);
						break;

					case game.JOY.BTN.LS:
						writeln("Panic!");
						break;
						
					case game.JOY.BTN.DPAD_UP:
						writeln("Prev setup");
						break;
					case game.JOY.BTN.DPAD_DOWN:
						writeln("Next setup");
						break;

				} break;

				//-------------------------------------------------------------
				// Releasing button
				//-------------------------------------------------------------

				case SDL_JOYBUTTONUP:
					break;

			}
		}
	}
}

//*****************************************************************************
//*****************************************************************************

void main()
{
	auto layer  = simple.init2D();
	auto actors = new game.FiberQueue();
	
	//-------------------------------------------------------------------------

	auto player = new Player();
	
	actors.add(&player.run);

	//-------------------------------------------------------------------------

	CooldownTimer timer = new CooldownTimer();

	//-------------------------------------------------------------------------

	TextBox skills[] = [
		new TextBox(layer, 100, 100, "Bladewall"),
		new TextBox(layer, 100, 120, "Bladestorm"),
	];
	
    gameloop: for(;;)
    {
		//---------------------------------------------------------------------
		
		render.start();
		
		layer.draw();
		
		game.waitframe();

		//---------------------------------------------------------------------
		
		foreach(event; game.getevents()) switch(event.type)
		{
			case SDL_JOYBUTTONDOWN:
			case SDL_JOYBUTTONUP:
				player.addevent(event);
				break;

		    default: break;
		}

		//---------------------------------------------------------------------

		actors.update();
	}
}
