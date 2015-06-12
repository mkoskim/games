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

    //-------------------------------------------------------------------------

    mat4 matrix() { return Transform.matrix(pos, rot, scale); }

    //-------------------------------------------------------------------------

    static Transform fixed(
        Transform parent = null,
        vec3 pos = vec3(0, 0, 0),
        vec3 rot = vec3(0, 0, 0),
        vec3 scale = vec3(1, 1, 1)
    )
    {
        return new Transform(parent, Transform.matrix(pos, rot, scale));
    }

    static Transform fixed(Transform parent, float x, float y, float z = 0)
    {
        return fixed(parent, vec3(x, y, z));
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

    static Transform movable(Transform parent, float x, float y, float z = 0)
    {
        return movable(parent, vec3(x, y, z));
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

    static mat4 matrix(vec3 pos, vec3 rot, vec3 scale)
    {
        return mat4.identity()
            .scale(scale.x, scale.y, scale.z)
            .rotatey(rot.y*2*PI/360)
            .rotatez(rot.z*2*PI/360)
            .rotatex(rot.x*2*PI/360)
            .translate(pos.x, pos.y, pos.z)
        ;
    }

    static mat4 matrix(float x, float y, float z = 0)
    {
        return matrix(vec3(x, y, z), vec3(0, 0, 0), vec3(1, 1, 1));
    }

    //-------------------------------------------------------------------------
    
    mat4 mModel() {
        if(last_updated != frame) update();
        return current;
    }

    private {
        int last_updated;
        mat4 current;
    }

    private void update()
    {
        if(grip) transform = grip.matrix();
        current = transform;
        if(parent) current = parent.mModel() * current;
        last_updated = frame;
    }

    //-------------------------------------------------------------------------

    vec3 worldspace(vec3 pos = vec3(0, 0, 0)) {
        return (mModel() * vec4(pos, 1)).xyz;
    }
}

