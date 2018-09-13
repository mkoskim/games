//*****************************************************************************
//
// Performance meter class: Uses simple sliding average
//
//*****************************************************************************

module engine.game.perfmeter;

//-----------------------------------------------------------------------------

import engine.util;

//-----------------------------------------------------------------------------

class PerfMeter : SlidingAverage
{
    private Clock clock;

    void start()   { clock.start(); }
    void stop()    { super.update(clock.elapsed()); }
    void restart() { stop(); start(); }
}

//-----------------------------------------------------------------------------



