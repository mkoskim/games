//*****************************************************************************
//
// Simply put: translate some ranges to different ranges. This is used for
// all kinds of animations, being it mesh deformation, moving objects around,
// floating points at screen, just anything that moves or morphs.
//
// In future, there is a plan to implement:
//
//      1) Translation with multiple ranges (like keyframes)
//
//      2) Discrete translation tables: some curves are easier to be
//         done numerically, to fit curve derivate at the end points
//         to some specific values.
//
//*****************************************************************************

module engine.math.translate;

import engine.math.util;

class Translate
{
    //-------------------------------------------------------------------------
    // Some basic translation functions. You can use your own custom
    // translate functions by feeding it to constructor.
    //-------------------------------------------------------------------------
    
    static float Linear(float factor) {
        return factor;
    }

    static float Cosine(float factor) {
        return 0.5*(1 - cos(PI*factor));
    }

    static float InOutQuad(float factor) {
        if(factor < 0.5)
            return 2*pow(factor, 2);
        else
            return -2*pow(factor - 1, 2) + 1;
    }

    //-------------------------------------------------------------------------
    // Values in range start.x ... end.x are translated to range start.y ..
    // end.y
    //-------------------------------------------------------------------------
    
    float function(float) mode;
    vec2 start, end;

    this(vec2 start, vec2 end, float function(float) mode = &Translate.Linear)
    {
        this.mode = mode;
        this.start = start;
        this.end = end;
    }

    //-------------------------------------------------------------------------

    float opCall(float pos) const
    {
        if(pos < start.x) return start.y;
        if(pos > end.x) return end.y;

        float factor = (pos - start.x) / (end.x - start.x);
        float delta  = (end.y - start.y);

        return start.y + mode(factor) * delta;
    }
}

