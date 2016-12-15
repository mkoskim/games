//*****************************************************************************
//
// Lights for rendering (sketch)
//
//*****************************************************************************

module engine.asset.types.light;

//-----------------------------------------------------------------------------

import engine.asset.util;
import engine.asset.types.transform;

//-----------------------------------------------------------------------------

class Light
{
    Transform transform;

    vec3 color;         // Light color (combining intensity also)
    float radius;       // Radius (linear attenuation)
    float ambient;      // Ambient lighting

    this(Transform transform, vec3 color, float radius, float ambient)
    {
        this.transform = transform;
        this.radius = radius;
        this.color = color;
        this.ambient = ambient;
    }
}

