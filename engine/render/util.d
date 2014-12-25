//*****************************************************************************
//
// Utilities for render modules
//
//*****************************************************************************

module engine.render.util;

//-----------------------------------------------------------------------------

public import engine.util;
public import derelict.opengl3.gl3;
public import gl3n.linalg;

//-----------------------------------------------------------------------------

void printmat(string name, mat4 matrix)
{
	writeln(name);
	foreach(row; matrix)
	{
		write("    ");
		foreach(val; row) writef("%+.2f ", val);
		writeln();
	}
}

//-----------------------------------------------------------------------------
//
// Checking & throwing GL errors, inspired by glamour. Usage:
//
//		checkgl!glFunctionCall(...);
//
//-----------------------------------------------------------------------------

import std.traits : ReturnType;
ulong glcalls = 0;

ReturnType!func checkgl(alias func, Args...)(Args args)
{
	//import std.stdio : stderr;
	import std.array : join;
	import std.range : repeat;
	import std.string : format;

	debug scope(success)
	{
		GLenum glerror = glGetError();
		if(glerror != GL_NO_ERROR)
		{
			throw new GLError(
				glerror,
				func.stringof,
				format("%s".repeat(Args.length).join(", "), args)
			);
		}
	}
	debug if(func is null)
	{
		throw new Error("%s is null! OpenGL loaded? Required OpenGL version not supported?".format(func.stringof));
	}

	glcalls++;
	return func(args);
}

//-----------------------------------------------------------------------------

class GLError : Exception
{
	string gl_error_string(GLenum error)
	{
		switch(error)
		{
			case GL_NO_ERROR: return "no error";
			case GL_INVALID_ENUM: return "invalid enum";
			case GL_INVALID_VALUE: return "invalid value";
			case GL_INVALID_OPERATION: return "invalid operation";
			//case GL_STACK_OVERFLOW: return "stack overflow";
			//case GL_STACK_UNDERFLOW: return "stack underflow";
			case GL_INVALID_FRAMEBUFFER_OPERATION: return "invalid framebuffer operation";
			case GL_OUT_OF_MEMORY: return "out of memory";
			default: return "unknown error";
		}
		//assert(false, "invalid enum");
	}

	this(GLenum error_code, string function_name, string args)
	{
		super(
			format(`OpenGL function "%s(%s)" failed: "%s."`,
				function_name,
				args,
				gl_error_string(error_code)
			)
		);
	}

	this(GLenum error_code)
	{
		super(format(`OpenGL error: "%s."`,gl_error_string(error_code)));
	}
}

