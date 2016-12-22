//*****************************************************************************
//
// Utilities for render modules
//
//*****************************************************************************

module engine.gpu.util;

//-----------------------------------------------------------------------------

public import engine.util;
public import derelict.opengl3.gl3;
public import gl3n.linalg;
public import std.variant: Variant;
public import std.string: toStringz;

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
// Count OpenGL calls. This is mostly resetted for each frame, so uint (4*10^9)
// just gotta be enough even on 64-bit machines.
//-----------------------------------------------------------------------------

uint glcalls = 0;   

//-----------------------------------------------------------------------------
//
// Checking & throwing GL errors, inspired by glamour. Usage:
//
//      checkgl!glFunctionCall(...);
//
//-----------------------------------------------------------------------------

import std.traits : ReturnType;

ReturnType!func checkgl(alias func, Args...)(Args args)
{
    import std.array : join;
    import std.range : repeat;
    import std.string : format;

    debug scope(success)
    {
        GLenum glerror = glGetError();
        if(glerror != GL_NO_ERROR)
        {
            string msg = gl_format_error(
                glerror,
                func.stringof,
                format("%s".repeat(Args.length).join(", "), args)
            );
            throw new Exception(msg);
        }
    }

    debug if(func is null)
    {
        throw new Error("%s is null! OpenGL loaded? Required OpenGL version not supported?".format(func.stringof));
    }

    glcalls++;
    return func(args);
}

private string gl_error_string(GLenum error)
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

private string gl_format_error(GLenum error_code, string func, string args)
{
    return format(`OpenGL function "%s(%s)" failed: "%s."`,
        func,
        args,
        gl_error_string(error_code)
    );
}
