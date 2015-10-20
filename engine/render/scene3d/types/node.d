//*****************************************************************************
//
// Rendering (scene) nodes
//
// UNDER REWORKING! Nodes are related to 'Batches' or layers or such.
// Different layers may hold different kind of instance data.
//
// Furthermore, nodes itselves have their pecularities. Some nodes
// may have LOD levels, meaning that the actual model (shape) to render depends
// on the distance of the object.
//
// And furthermore, there are different kind of 'strategies' for rendering
// game scenes. Depending on the content, e.g.
//
// - Use instanced draw
// - Sort drawing order (back to front, front to back)
// - Frustum culling
// - Portals and occluders
// - BSP etc
//
//*****************************************************************************

module engine.render.scene3d.types.node;

//-------------------------------------------------------------------------

import engine.render.util;

import engine.render.scene3d.types.transform;
import engine.render.scene3d.types.model;
import engine.render.scene3d.types.view;

//-------------------------------------------------------------------------
// Nodes are drawable objects that combine transform with shape
//-------------------------------------------------------------------------

class Node
{
    Model model;
    Transform transform;

    //-------------------------------------------------------------------------

    @property Grip grip()
    {
        if(!transform.grip) throw new Exception("Cannot move static nodes");
        return transform.grip;
    }

    //-------------------------------------------------------------------------

    this(Transform transform, Model model)
    {
        this.transform = transform;
        this.model = model;
    }

    //-------------------------------------------------------------------------

    vec3 worldspace(vec3 local = vec3(0, 0, 0)) {
        return transform.worldspace(local);
    }

    float distance(Node node) {
        return worldspace.distance(node.worldspace);
    }

    //-------------------------------------------------------------------------
    // Cached values... TODO: These should be tied to camera, and render
    // batch.
    //-------------------------------------------------------------------------

    struct VIEWSPACE {
        vec3 bsp;       // Bounding sphere position relative to camera
        float bspdst2;  // Bouding sphere (squared) distance to camera

        int infrustum;  // = INSIDE, INTERSECT or OUTSIDE
    }

    VIEWSPACE viewspace;

    void project(View cam)
    {
        viewspace.bsp = cam.viewspace(transform.mModel(), model.vao.bsp.center);
        viewspace.bspdst2 = viewspace.bsp.magnitude_squared;

        viewspace.infrustum = INSIDE;
        foreach(plane; cam.frustum.planes)
        {
            float dist = plane.distance(viewspace.bsp);
            if (dist < -model.vao.bsp.radius)
            {
                viewspace.infrustum = OUTSIDE;
                break;
            }
            else if(dist < model.vao.bsp.radius)
            {
                viewspace.infrustum = INTERSECT;
            }
        }
    }
}

