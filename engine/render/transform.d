//*****************************************************************************
//
// Transforms
//
//*****************************************************************************

module engine.render.transform;

//-------------------------------------------------------------------------

import engine.render.util;

import engine.game: frame;

//-------------------------------------------------------------------------

private mat4 getmatrix(vec3 pos, vec3 rot, vec3 scale)
{
    return mat4.identity()
        .scale(scale.x, scale.y, scale.z)
        .rotatey((2*PI/360)*rot.y)
        .rotatez((2*PI/360)*rot.z)
        .rotatex((2*PI/360)*rot.x)
        .translate(pos.x, pos.y, pos.z)
    ;
}

//-------------------------------------------------------------------------

class Grip
{
    vec3 pos, rot, scale;

    this(
        vec3 pos = vec3(0, 0, 0),
        vec3 rot = vec3(0, 0, 0),
        vec3 scale = vec3(1, 1, 1)
    )
    {
        this.pos = pos;
        this.rot = rot;
        this.scale = scale;
    }

    mat4 matrix() { return getmatrix(pos, rot, scale); }

    //-------------------------------------------------------------------------

    static Transform fixed(
        Transform parent = null,
        vec3 pos = vec3(0, 0, 0),
        vec3 rot = vec3(0, 0, 0),
        vec3 scale = vec3(1, 1, 1)
    )
    {
        return new Transform(parent, getmatrix(pos, rot, scale));
    }

    static Transform fixed(vec3 pos, vec3 rot = vec3(0, 0, 0), vec3 scale = vec3(1, 1, 1))
    {
        return fixed(null, pos, rot, scale);
    }

    static Transform fixed(float x, float y, float z = 0)
    {
        return fixed(vec3(x, y, z));
    }

    //-------------------------------------------------------------------------

    static Transform movable(
        Transform parent = null,
        vec3 pos = vec3(0, 0, 0),
        vec3 rot = vec3(0, 0, 0),
        vec3 scale = vec3(1, 1, 1)
    )
    {
        return new Transform(parent, new Grip(pos, rot, scale));
    }

    static Transform movable(vec3 pos, vec3 rot = vec3(0, 0, 0), vec3 scale = vec3(1, 1, 1))
    {
        return movable(null, pos, rot, scale);
    }

    static Transform movable(float x, float y, float z = 0)
    {
        return movable(vec3(x, y, z));
    }
}

//-------------------------------------------------------------------------

class Transform
{
    Transform parent;
    mat4 transform;
    Grip grip;

    //-------------------------------------------------------------------------

    this(Transform parent, mat4 transform)
    {
        this.parent = parent;
        this.transform = transform;
    }
    
    this(Transform parent, Grip grip)
    {
        this.parent = parent;
        this.grip = grip;
    }
    
    this(mat4 transform) { this(null, transform); }
    this(Grip grip) { this(null, grip); }

    //-------------------------------------------------------------------------
    
    int last_updated;
    mat4 current;

    mat4 mModel() {
        if(last_updated != frame) 
        {
            if(grip) transform = grip.matrix();
            current = transform;
            if(parent) current = parent.mModel() * current;
        }
        return current;
    }

    //-------------------------------------------------------------------------

    vec3 worldspace(vec3 pos = vec3(0, 0, 0)) {
        return (mModel() * vec4(pos, 1)).xyz;
    }
}

