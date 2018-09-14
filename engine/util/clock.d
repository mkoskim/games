//*****************************************************************************
//
// Clock() helps measuring time between events.
//
//*****************************************************************************

module engine.util.clock;

import core.time;

struct Clock
{
    MonoTime ticks;
    
    void  start()   { ticks = MonoTime.currTime; }
    float elapsed() { return (MonoTime.currTime - ticks).total!"nsecs" * 1e-9; }
}
