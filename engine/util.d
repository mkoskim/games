//*****************************************************************************
//
// Miscellaneous utility functions for both game and render engines.
//
//*****************************************************************************

module engine.util;

public import derelict.sdl2.sdl;
public import derelict.opengl3.gl3;
public import gl3n.linalg;

public import std.stdio: writeln, writefln, write, writef;
public import std.string: format;
public import std.conv: to;

public import std.math: fabs;

//-----------------------------------------------------------------------------

void TODO(string msg = null, string file = __FILE__, int line = __LINE__, string func = __FUNCTION__)
{
	//return;
	//throw new Exception("Not done yet.");
	if(msg)
	{
		writefln("TODO: %s (%s)", msg, func);
	}
	else
	{
		writefln("TODO: %s", func);
	}
}

//-----------------------------------------------------------------------------
//
// Manhattan distance is pretty quick to calculate, but probably nowadays
// squared distance (x*x + y*y + z*z) is as fast.
//
//-----------------------------------------------------------------------------

import std.math: abs;

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
		const float window = 10.0;
		average += (value - average) / window;
	}
}

//-----------------------------------------------------------------------------

import std.conv : to;

int _sdlattr(alias func)(int arg)
{
	int result;
	func(arg, &result);
	return result;
}

string _sdlattr2str(alias func, string arg)()
{
	int result;
	func(mixin(arg), &result);
	return arg ~ " = " ~ to!string(result);
}

