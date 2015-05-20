//*****************************************************************************
//
// Games have awfully lots of concurrent action. Let's check if D Fiber
// can help with that.
//
//*****************************************************************************

module engine.game.fiber;

//-----------------------------------------------------------------------------

import core.thread: CoreFiber = Fiber;
import std.algorithm: remove, SwapStrategy;

//-----------------------------------------------------------------------------

import std.stdio: writeln;
import derelict.sdl2.sdl: SDL_GetTicks;
import engine.game: Profile;

//-----------------------------------------------------------------------------

class Fiber : CoreFiber
{
    this(void delegate() dg) { super(dg); }
    this() { this(&run); }

    this(FiberQueue queue) {
        this();
        queue.add(this);
    }

    this(FiberQueue queue, void delegate() dg) {
        this(dg);
        queue.add(this);
    }

    void nextframe() { yield(); }

    void run() { }
}

//-----------------------------------------------------------------------------

class FiberQueue
{
    private bool[void delegate()] callbacks;
    private Fiber[] queue;

    void add(Fiber f) { queue ~= f; }
    void add(void delegate() f) { queue ~= new Fiber(f); }

    void addcallback(void delegate() f) { callbacks[f] = true; }
    void removecallback(void delegate() f) { callbacks.remove(f); }

    void update()
    {
        foreach(callback; callbacks.keys) callback();

        if(queue.length) {
            foreach(f; queue) f.call();

            queue = queue.remove!(
                f => f.state == Fiber.State.TERM,
                SwapStrategy.unstable
            );
        }
    }

    //-------------------------------------------------------------------------

    void reportperf()
    {
        addcallback(() {
            static int ticks = 0;
            if(SDL_GetTicks() - ticks < 1000) return;
            writeln(Profile.info());
            ticks = SDL_GetTicks();
        });
    }
}

//-----------------------------------------------------------------------------


