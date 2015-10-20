//*****************************************************************************
//
// Lights for rendering (sketch)
//
//*****************************************************************************

module engine.render.scene3d.types.light;

//-----------------------------------------------------------------------------

import engine.render.util;
import engine.render.scene3d.types.transform;

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
