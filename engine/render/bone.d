//*****************************************************************************
//
// Bones are used to divide transforms (translation and rotation) to
// manageable phases.
//
// TODO: Think how to make optimizations, so that constant transformations
// are calculated only once, and dynamic ones just once per frame. Although
// optimizations are not needed here that badly, it is good to prepare for
// it.
//
//*****************************************************************************

module engine.render.bone;

//-------------------------------------------------------------------------

import engine.render.util;

//-------------------------------------------------------------------------

class Bone
{
    //protected static bool[Bone] _cache;

    static void clearcache()
    {
        /*
        _cache.rehash;
        foreach(k, v; _cache) _cache[k] = false;
        //debug writeln("Transformation cache: ", _cache.length);
        */
    }

    //-------------------------------------------------------------------------
    
    Bone parent;
    mat4 transform;
    vec3 pos, rot, scale;

    //-------------------------------------------------------------------------
    
    this(Bone parent,
        vec3 pos = vec3(0, 0, 0),
        vec3 rot = vec3(0, 0, 0),
        vec3 scale = vec3(1, 1, 1)
    )
    {
        this.parent = parent;
        this.pos = pos;
        this.rot = rot;
        this.scale = scale;
        //_cache[this] = false;
    }

    this(vec3 pos, vec3 rot = vec3(0, 0, 0)) { this(null, pos, rot); }
    
    //-------------------------------------------------------------------------
    
    mat4 mModel() {
        //if(!_cache[this])
        {
            transform = parent ?
                parent.mModel() * get(pos, rot, scale) :
                get(pos, rot, scale)
            ;
            
            //_cache[this] = true;
        }
        return transform;
    }

    //-------------------------------------------------------------------------

    mat4 get(vec3 pos, vec3 rot, vec3 scale = vec3(1, 1, 1))
    {
        return mat4.identity()
            .scale(scale.x, scale.y, scale.z)
            .rotatey((2*PI/360)*rot.y)
            .rotatez((2*PI/360)*rot.z)
            .rotatex((2*PI/360)*rot.x)
            .translate(pos.x, pos.y, pos.z)
        ;
    }
    
}

