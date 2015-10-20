//*****************************************************************************
//
// Transforms
//
//*****************************************************************************

module engine.render.scene3d.types.transform;

//-------------------------------------------------------------------------

import engine.render.util;

//-------------------------------------------------------------------------
// Grip is (basically) any kind of object that can output a 4x4 transform
// matrix. Grip is used for various movable objects.
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
    // Creating fixed transforms
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
    // Creating movable transforms
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
//
// Transform is base class for 4x4 transformation matrix. It has
// reference to a grip object to update the transformation. Transformations
// form a tree that is generally formed by scene graph. Currently,
// transformation tree is separated from nodes to allow higher degree of
// freedom to decide how to store objects.
//
//-------------------------------------------------------------------------

private import engine.game: frame;

class Transform
{
    Transform parent;
    mat4 transform;
    Grip grip;

    //-------------------------------------------------------------------------

    private this(Transform parent) { Track.add(this); this.parent = parent; }
    private ~this() { Track.remove(this); }

    //-------------------------------------------------------------------------

    this(Transform parent, mat4 transform)
    {
        this(parent);
        this.transform = transform;
    }
    
    this(Transform parent, Grip grip)
    {
        this(parent);
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
    
    private {
        int last_updated;
        mat4 current;

        void update()
        {
            if(grip) transform = grip.matrix();
            current = transform;
            if(parent) current = parent.mModel() * current;
            last_updated = frame;
        }
    }

    //-------------------------------------------------------------------------
    
    mat4 mModel() {
        if(last_updated != frame) update();
        return current;
    }


    //-------------------------------------------------------------------------

    vec3 worldspace(vec3 pos = vec3(0, 0, 0)) {
        return (mModel() * vec4(pos, 1)).xyz;
    }
}

