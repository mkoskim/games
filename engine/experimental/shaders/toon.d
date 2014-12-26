//*****************************************************************************
//
// Toon shader (currently broken)
//
//*****************************************************************************

module engine.render.shaders.toon;

import engine.render.shaders.base;
import engine.render.shaders.defaults: Default3D;

class Toon3D_broken : Default3D
{
	static Shader create()
	{
		static Shader instance = null;
		//if(!instance) instance = new Toon3D();
		return instance;
	}

	//-------------------------------------------------------------------------

	//private this() { }
}
