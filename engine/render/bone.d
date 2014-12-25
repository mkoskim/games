//*****************************************************************************
//
// Bones are used to divide transforms (translation and rotation) to
// manageable phases.
//
//*****************************************************************************

module engine.render.bone;

//-------------------------------------------------------------------------

import engine.render.util;

//-------------------------------------------------------------------------

class Bone
{
	Bone parent;

	vec3 pos;
	vec3 rot;

	this(Bone parent, vec3 pos = vec3(0, 0, 0), vec3 rot = vec3(0, 0, 0))
	{
		this.parent = parent;
		this.pos = pos;
		this.rot = rot;
	}
	
	//-------------------------------------------------------------------------

	this(vec3 pos, vec3 rot = vec3(0, 0, 0))
	{
		this(null, pos, rot);
	}

	//-------------------------------------------------------------------------

	mat4 mModel()
	{	
		mat4 m = mat4.identity()
			//.scale(scale.x, scale.y, scale.z)
			.rotatey((2*PI/360)*rot.y)
			.rotatez((2*PI/360)*rot.z)
			.rotatex((2*PI/360)*rot.x)
			.translate(pos.x, pos.y, pos.z)
		;
		return parent ? parent.mModel() * m : m;
	}
}


