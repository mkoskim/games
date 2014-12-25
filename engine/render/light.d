//*****************************************************************************
//
// Lights for rendering
//
//*****************************************************************************

module engine.render.light;

//-----------------------------------------------------------------------------

import engine.render.util;
import engine.render.bone;

//-----------------------------------------------------------------------------

class Light
{
	Bone grip;

	vec3 color;			// Light color (combining intensity also)
	float radius;		// Radius (linear attenuation)
	float ambient;		// Ambient lighting

	this(vec3 pos, vec3 color, float radius, float ambient)
	{
		this.grip = new Bone(pos);
		this.radius = radius;
		this.color = color;
		this.ambient = ambient;
	}
}

