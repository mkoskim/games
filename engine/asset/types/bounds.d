//*****************************************************************************
//
// Bounding volumes
//
//*****************************************************************************

module engine.asset.types.bounds;

//-----------------------------------------------------------------------------

import engine.asset.util;
import engine.asset.types.mesh;

//-----------------------------------------------------------------------------
// Bounding sphere
//-----------------------------------------------------------------------------

class BoundSphere
{
    vec3 center;
    float radius;

    static BoundSphere create(Mesh mesh)
    {
        vec3 center = vec3(0, 0, 0);
        foreach(vertex; mesh.vertices) center += vertex.pos;
        center = center * (1.0/mesh.vertices.length);

        float radius = 0;
        foreach(vertex; mesh.vertices)
        {
            radius = max(radius, (vertex.pos - center).magnitude);
        }

        return new BoundSphere(center, radius);
    }

    //-------------------------------------------------------------------------

    private this(vec3 center, float radius)
    {
        this.center = center;
        this.radius = radius;
    }
}

