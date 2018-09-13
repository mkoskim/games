//*****************************************************************************
//
// Game engine math
//
//*****************************************************************************

module engine.math;

public import gl3n.linalg;
public import std.math;

public import engine.math.translate;

//-----------------------------------------------------------------------------
//
// Manhattan distance is pretty quick to calculate, but probably nowadays
// squared distance (x*x + y*y + z*z) is as fast.
//
//-----------------------------------------------------------------------------

float manhattan(vec3 a, vec3 b)
{
    return abs(b.x-a.x) + abs(b.y-a.y) + abs(b.z-a.z);
}

//-----------------------------------------------------------------------------
//
// Sliding average is useful for various performance meters.
//
//-----------------------------------------------------------------------------

class SlidingAverage
{
    float average = 0;

    void update(float value)
    {
        const float window = 5.0;
        average += (value - average) / window;
    }
}

