//*****************************************************************************
//
// Different more specialized types to be used mainly to pack vertex data.
// These are packed structs, and not intended to be used at CPU side
// calculations (unpack them for modifying).
//
//*****************************************************************************

module engine.render.shaders.gputypes;

//-----------------------------------------------------------------------------

import engine.render.util;
import std.bitmanip;

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------

struct ivec4x8b
{
    static immutable GLenum gltype = GL_BYTE;
    static immutable GLenum glsize = 4;
    static immutable bool glnormd = true;

    byte x, y, z, w;

    static assert(ivec4x8b.sizeof == 4);

    this(vec4 v) { pack(v); }

    static immutable float scale = 127;

    void pack(vec4 v) {
        x = cast(typeof(x))(v.x * scale);
        y = cast(typeof(y))(v.y * scale);
        z = cast(typeof(z))(v.z * scale);
        w = cast(typeof(w))(v.w * scale);
    }

    vec4 unpack() {
        return vec4(
            x / scale,
            y / scale,
            z / scale,
            w / scale
        );
    }
}

//-----------------------------------------------------------------------------
// GPU half-float
//-----------------------------------------------------------------------------

struct halffloat
{
    enum uint
        fractionBits = 10,
        exponentBits = 5,
        bias = (1 << (exponentBits-1)) - 1;

    mixin(bitfields!(
        uint, "fraction", fractionBits,
        ubyte, "exponent", exponentBits,
        bool, "sign", 1)
    );

    static assert(halffloat.sizeof == 2);

    void pack(float f)
    {
        FloatRep v;
        v.value = f;

        sign = v.sign;
        exponent = v.exponent ? cast(ubyte)(cast(int)(v.exponent - v.bias) + bias) : 0;
        fraction = v.fraction >> (v.fractionBits - fractionBits);
    }

    float unpack()
    {
        FloatRep v;

        v.sign = sign;
        v.exponent = exponent ? cast(ubyte)(cast(int)(exponent - bias) + v.bias) : 0;
        v.fraction = fraction << (v.fractionBits - fractionBits);

        return v.value;
    }
}

//-----------------------------------------------------------------------------

struct fvec2x16b
{
    halffloat x, y;

    static assert(fvec2x16b.sizeof == 4);

    static immutable GLenum gltype = GL_HALF_FLOAT;
    static immutable GLenum glsize = 2;
    static immutable bool glnormd = false;

    this(vec2 v) { pack(v); }

    void pack(vec2 v) { x.pack(v.x); y.pack(v.y); }
    vec2 unpack() { return vec2(x.unpack(), y.unpack()); }
}

//-----------------------------------------------------------------------------
// TODO: For some reason, glVertexAttribPointer returns invalid enum
// when using GL_INT_2_10_10_10_REV, so this is untested.
//-----------------------------------------------------------------------------

struct ivec3x10b
{
    static immutable GLenum gltype = GL_INT_2_10_10_10_REV;
    static immutable GLenum glsize = 4;
    static immutable bool glnormd = true;

    mixin(bitfields!(
        int, "x", 10,
        int, "y", 10,
        int, "z", 10,
        int, "w", 2)
    );

    static assert(ivec3x10b.sizeof == 4);

    this(vec4 v) { pack(v); }

    static immutable float scale = 511;

    void pack(vec4 v) {
        x = cast(typeof(x))(v.x * scale);
        y = cast(typeof(y))(v.y * scale);
        z = cast(typeof(z))(v.z * scale);
        w = cast(typeof(w))(v.w);
    }

    vec4 unpack() {
        return vec4(
            x / scale,
            y / scale,
            z / scale,
            w
        );
    }
}

