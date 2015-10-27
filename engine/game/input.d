//*****************************************************************************
//
// User input
//
// Unlike regular GUI applications, many times games want 'direct' queries
// to input device status: for example, checking if key is up or down somewhere
// in frame update process. Instead of forcing all games to create their own
// buffers for queries, we create one, keep it up-to-date, and let games
// use it.
//
// But, on the other hand, games *also* need to get events when something
// happens (player presses a key) for certain things. So, we provide event
// based input, too.
//
//*****************************************************************************

module engine.game.input;

import derelict.sdl2.sdl;

import engine.game.util;
import engine.game.instance: controller;

//-----------------------------------------------------------------------------
// Game controller class
//-----------------------------------------------------------------------------

abstract class Joystick
{
    float[] axes;
    byte[]  buttons;
    byte[]  hats;

    //-------------------------------------------------------------------------

    abstract string name();

    static Joystick[] available() { return cast(Joystick[])controllers ~ cast(Joystick)emulated; }

    //-------------------------------------------------------------------------

    package static Joystick chosen = null;

    package static void init()
    {
        SDL_InitSubSystem(SDL_INIT_JOYSTICK);

        int num = SDL_NumJoysticks();

        foreach(i; 0 .. num) {
            controllers ~= new GameController(i);
        }

        emulated = new EmulatedController();
        
        chosen = (controllers) ? controllers[0] : emulated;
    }
}

package GameController[] controllers;
package EmulatedController emulated;

//-----------------------------------------------------------------------------
// Controller (XBox/360) definitions
//-----------------------------------------------------------------------------

struct JOY
{
    //-------------------------------------------------------------------------

    enum AXIS : uint {
        NONE = -1,

        LX = 0, LY, LT,     // Left X & Y, and left trigger
        RX = 3, RY, RT,     // Right X & Y, and right trigger

        COUNT               // Count of axes
    }

    //-------------------------------------------------------------------------

    enum BTN : uint {
        NONE = -1,

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

        LS_LEFT, LS_RIGHT,      // Left stick X
        LS_UP, LS_DOWN,         // Left stick Y
        LT_FREE, LT,            // Left trigger

        RS_LEFT, RS_RIGHT,      // Right stick X
        RS_UP, RS_DOWN,         // Right stick Y
        RT_FREE, RT,            // Right trigger

        //---------------------------------------------------------------------
        // Emulated "hat buttons": Each hat has four virtual buttons: left,
        // right, up and down. Keep the order the same direction masks are
        // in button emulation code.
        //---------------------------------------------------------------------

        DPAD_LEFT, DPAD_RIGHT,
        DPAD_UP, DPAD_DOWN,
        
        COUNT
    }
}

//-----------------------------------------------------------------------------
// Keyboard status
//-----------------------------------------------------------------------------

bool[uint] keystatus;

bool keydown(uint keycode) { return keycode in keystatus && keystatus[keycode]; }
bool keyup(uint keycode)   { return !keydown(keycode); }

//-----------------------------------------------------------------------------
// Emulated joystick: emulate game controller with keyboard and mouse.
// TODO: Provide interface for game to set default emulation.
// TODO: Provide interface for game to configure emulation.
// TODO: Button emulation should send joy button event.
//-----------------------------------------------------------------------------

struct EMULATE { JOY.AXIS axis; float value; JOY.BTN btn; }

EMULATE[SDL_Keycode] Arrows() { return [
    SDLK_RIGHT: EMULATE(JOY.AXIS.LX, +1, JOY.BTN.LS_RIGHT),
    SDLK_LEFT:  EMULATE(JOY.AXIS.LX, -1, JOY.BTN.LS_LEFT),
    SDLK_DOWN:  EMULATE(JOY.AXIS.LY, +1, JOY.BTN.LS_DOWN),
    SDLK_UP:    EMULATE(JOY.AXIS.LY, -1, JOY.BTN.LS_UP),
]; }

EMULATE[SDL_Keycode] WASDArrows() { return [
    SDLK_d: EMULATE(JOY.AXIS.LX, +1, JOY.BTN.LS_RIGHT),
    SDLK_a: EMULATE(JOY.AXIS.LX, -1, JOY.BTN.LS_LEFT),
    SDLK_s: EMULATE(JOY.AXIS.LY, +1, JOY.BTN.LS_DOWN),
    SDLK_w: EMULATE(JOY.AXIS.LY, -1, JOY.BTN.LS_UP),

    SDLK_RIGHT: EMULATE(JOY.AXIS.RX, +1, JOY.BTN.LS_RIGHT),
    SDLK_LEFT:  EMULATE(JOY.AXIS.RX, -1, JOY.BTN.LS_LEFT),
    SDLK_DOWN:  EMULATE(JOY.AXIS.RY, +1, JOY.BTN.LS_DOWN),
    SDLK_UP:    EMULATE(JOY.AXIS.RY, -1, JOY.BTN.LS_UP),
];}

package class EmulatedController : Joystick
{
    EMULATE[SDL_Keycode] emulate;
    
    this()
    {
        axes    = new float[JOY.AXIS.COUNT];
        buttons = new byte[JOY.BTN.COUNT];

        axes[0 .. $]    = 0.0;
        buttons[0 .. $] = false;

        emulate = Arrows;
    }

    override string name() { return "Keyboard & Mouse"; }

    void update(SDL_Event event) {
        switch(event.type) {
            case SDL_KEYUP, SDL_KEYDOWN: break;
            default: return;
        }

        SDL_Keycode key = event.key.keysym.sym;

        if(key in emulate) {
            EMULATE e = emulate[key];
            bool pressed = (event.type == SDL_KEYDOWN);
            
            if(e.axis != JOY.AXIS.NONE) axes[e.axis]  = pressed ? e.value : 0;
            if(e.btn  != JOY.BTN.NONE)
            {
                buttons[e.btn] = pressed;

                SDL_Event ev;
                ev.type           = pressed ? SDL_JOYBUTTONDOWN : SDL_JOYBUTTONUP;
                ev.jbutton.which  = cast(int)controllers.length;
                ev.jbutton.button = cast(ubyte)e.btn;
                ev.jbutton.state  = pressed;
                SDL_PushEvent(&ev);
            }
        }
    }
}

//-----------------------------------------------------------------------------
// Real game controllers
//-----------------------------------------------------------------------------

package class GameController : Joystick
{
    //-------------------------------------------------------------------------

    private static const float AXIS_TRESHOLD = 0.05;
    private uint AXISBTN_FIRST;
    private uint HATBTN_FIRST;

    //-------------------------------------------------------------------------
    //
    // Joystick status update from event. The most important thing done here
    // is to create "emulated" buttons from axes and hats, to simplify using
    // them like arrow keys.
    //
    //-------------------------------------------------------------------------

    protected float axisvalue(int axis) {
        float value = (axis + 0.5) / 32768.0;
        return (abs(value) < AXIS_TRESHOLD) ? 0.0 : value;
    }

    void update(SDL_Event event)
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
                float value = axisvalue(event.jaxis.value);
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

    override string name() {
        return to!string(SDL_JoystickName(stick));
    }

    //-------------------------------------------------------------------------

    private SDL_Joystick *stick;    // SDL Joystick
    private SDL_Haptic *ffb;        // SDL Force Feedback

    this(int num)
    {
        debug Track.add(this);

        stick = SDL_JoystickOpen(num);

        if(SDL_JoystickIsHaptic(stick) == 1) {
            ffb = SDL_HapticOpenFromJoystick(stick);
        } else {
            ffb = null;
        }

        axes = new float[SDL_JoystickNumAxes(stick)];
        hats = new byte[SDL_JoystickNumHats(stick)];

        buttons = new byte[
            SDL_JoystickNumButtons(stick)   // Normal buttons
            + 2*axes.length                 // Emulated axis buttons
            + 4*hats.length                 // Emulated hat buttons
        ];

        AXISBTN_FIRST = SDL_JoystickNumButtons(stick);
        HATBTN_FIRST  = AXISBTN_FIRST + cast(uint)axes.length*2;

        SDL_JoystickUpdate();

        foreach(i; 0 .. buttons.length) buttons[i] = SDL_JoystickGetButton(stick, cast(int)i);
        foreach(i; 0 .. hats.length)    hats[i] = SDL_JoystickGetHat(stick, cast(int)i);
        foreach(i; 0 .. axes.length)    axes[i] = axisvalue(SDL_JoystickGetAxis(stick, cast(int)i));

        SDL_JoystickEventState(SDL_ENABLE);

        debug writefln("Joystick#%d: %s (haptic: %s)",
            num,
            to!string(SDL_JoystickName(stick)),
            ffb ? "yes" : "no"
        );
    }

    ~this()
    {
        debug Track.remove(this);
        SDL_JoystickClose(stick);
        if(ffb) SDL_HapticClose(ffb);
    }
}
