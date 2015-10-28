//*****************************************************************************
//
// Layer is a bunch of rendered objects.
//
// TO BE REWORKED! Layers are integrated to 'blitter' object, which combines
// shader control, layers and such together.
//
//*****************************************************************************

//*****************************************************************************
//
// We need:
//
// 1) Object storages
// 2) Batches to shader
// 3) Structures that go through object storages and form shader batches
//
//*****************************************************************************

module engine.render.scene3d.layer;

//-----------------------------------------------------------------------------

import engine.render.util;
import engine.render.loader.mesh;

import gpu = engine.render.gpu.state;

import engine.render.scene3d.types.transform;
import engine.render.scene3d.types.material;
import engine.render.scene3d.types.model;
import engine.render.scene3d.types.node;
import engine.render.scene3d.types.view;
import engine.render.scene3d.types.light;

import engine.render.scene3d.feeder;
import engine.render.scene3d.batch;

import engine.game.fiber;

//*****************************************************************************
//
// Object storage
//
//*****************************************************************************

abstract class NodeGroup
{
    //-------------------------------------------------------------------------

    abstract Node _add(Node node);
    abstract void remove(Node node);

    //-------------------------------------------------------------------------
    // By default, we add immovable objects, as guess is that they dominate
    // scenes. BTW, immovable node is not necessarily that immovable, it may
    // contain skeleton - which can, in addition to deform mesh, also move
    // the mesh around...
    //-------------------------------------------------------------------------

    Node add(Node node) { return _add(node); }

    Node add(Transform transform, Model model) { return _add(new Node(transform, model)); }
    Node add(vec3 pos, Model model) { return add(Grip.fixed(pos), model); }
    Node add(float x, float y, float z, Model model) { return add(Grip.fixed(x, y, z), model); }
    Node add(float x, float y, Model model) { return add(Grip.fixed(x, y), model); }
}

//-----------------------------------------------------------------------------
// CollectableRenderGroup has collect() method, for using camera to pick
// nodes to batchgroup.
//-----------------------------------------------------------------------------

abstract class CollectableNodeGroup : NodeGroup
{
    abstract void collect(View cam, BatchGroup batches);
}

//-----------------------------------------------------------------------------

class BasicNodeGroup : CollectableNodeGroup
{
    bool[Node] nodes;

    size_t length() { return nodes.length; }

    this() { }
    
    override Node _add(Node node) { nodes[node] = true; return node; }
    override void remove(Node node) { nodes.remove(node); }

    void clear() { foreach(node, _; nodes) remove(node); }

    override void collect(View cam, BatchGroup batches)
    {
        foreach(node, _; nodes) {
            node.project(cam);
            if(!node.viewspace.infrustum) continue;
            batches.add(node);
        }
    }
}

//*****************************************************************************
//
// Buffered rendering: Models (Mesh + Material) are separated from
// Nodes (Model + transform). Nodes are collected from node groups, and
// added to batches depending on the model.
//
//*****************************************************************************

class BufferedRender
{
    View cam;
    Light light; // HACK!

    BatchGroup batches;             // Rendering batches
    CollectableNodeGroup[] groups;  // Scene node groups
    
    NodeGroup nodes;

    FiberQueue actors;
    
    //-------------------------------------------------------------------------

    this()
    {
        batches = new BatchGroup();
        nodes = addgroup();
        actors = new FiberQueue();
    }

    //-------------------------------------------------------------------------

    Batch addbatch(Batch batch) { return batches.addbatch(batch); }
    Batch addbatch(gpu.State state) { return batches.addbatch(state); }
    Batch addbatch(gpu.State state, Batch.Mode mode) { return batches.addbatch(state, mode); }
    Batch addbatch(Batch batch, Batch.Mode mode) { return batches.addbatch(batch, mode); }

    CollectableNodeGroup addgroup(CollectableNodeGroup group) { groups ~= group; return group; }
    CollectableNodeGroup addgroup() { return addgroup(new BasicNodeGroup()); }

    //-------------------------------------------------------------------------

    void draw()
    {
        batches.clear();
        foreach(group; groups) group.collect(cam, batches);

        // TODO: Hack! Design light subsystem
        if(light) {
            batches.batches[0].activate();    
            batches.batches[0].light(light);
        }

        batches.draw(cam);
    }
}

//*****************************************************************************
//
// Unbuffered node storage: stores nodes directly to batches, and renders
// them in order which batches are created. No culling is applied.
//
//*****************************************************************************

class UnbufferedRender : NodeGroup
{
    gpu.State state;

    View cam;
    Light light;
    BatchGroup batches;
    
    //-------------------------------------------------------------------------

    this(View cam, gpu.State state)
    {
        this.state = state;
        this.cam = cam;
        this.batches = new BatchGroup();
    }

    //-------------------------------------------------------------------------

    override Node _add(Node node) { batches.add(node); return node; }
    override void remove(Node node) { batches.remove(node); }    

    //-------------------------------------------------------------------------

    Batch addbatch() { return batches.addbatch(new Batch(state)); }

    //-------------------------------------------------------------------------

    void draw()
    {
        // TODO: Hack! Design light subsystem
        if(light) {
            batches[0].activate();    
            batches[0].light(light);
        }
        
        batches.draw(cam);
    }
}

