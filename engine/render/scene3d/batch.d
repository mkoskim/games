//*****************************************************************************
//
// Batch: The idea is that when nodes are collected from
// scene graph(s), they can be classified and thus moved to right batch.
//
//*****************************************************************************

module engine.render.scene3d.batch;

//-----------------------------------------------------------------------------

import engine.render.util;
import engine.render.loader.mesh;

import engine.render.gpu.texture;
import gpu = engine.render.gpu.state, engine.render.gpu.shader;

import engine.render.scene3d.types.transform;
import engine.render.scene3d.types.bounds;
import engine.render.scene3d.types.material;
import engine.render.scene3d.types.model;
import engine.render.scene3d.types.node;
import engine.render.scene3d.types.view;

import engine.render.scene3d.feeder;

import std.algorithm;

//*****************************************************************************
//
// Batch: Hold collected models, and rendering state. Separate this to few
// different parts... I need batches which sort collected nodes, and so
// on.
//
// Also, there may be need for "multi target" batches?
//
//*****************************************************************************

class Batch : Feeder
{
    enum Mode { unsorted, front2back, back2front };
    Mode mode;

    this(gpu.State state, Mode mode = Mode.unsorted) {
        super(state);
        this.mode = mode;
    }

    this(Batch batch, Mode mode) { this(batch.state, mode); }
    this(Batch batch) { this(batch.state, batch.mode); }

    //-------------------------------------------------------------------------

    static Batch Solid3D() { return new Batch(State.Solid3D(), Mode.front2back); }
    static Batch Solid3D(gpu.Shader shader) { return new Batch(State.Solid3D(shader), Mode.front2back); }
    static Batch Solid3D(gpu.State state) { return new Batch(state, Mode.front2back); }

    static Batch Transparent3D() { return new Batch(State.Transparent3D(), Mode.back2front); }
    static Batch Transparent3D(gpu.Shader shader) { return new Batch(State.Transparent3D(shader), Mode.back2front); }
    static Batch Transparent3D(gpu.State state) { return new Batch(state, Mode.back2front); }

    //-------------------------------------------------------------------------
    // Asset management... Needs to be restructured
    //-------------------------------------------------------------------------

    VAO[Mesh] meshes;

    override VAO upload(Mesh mesh)
    {
        if(!(mesh in meshes))
        {
            meshes[mesh] = super.upload(mesh);
        }
        return meshes[mesh];
    }

    //-------------------------------------------------------------------------
    // Models managed by this batch: currently, this is mainly used to
    // classify incoming nodes to correct batches.
    //
    // Loading empty model is used to create 'placeholders'
    //
    //-------------------------------------------------------------------------

    bool[Model] models;

    Model upload(Model model)
    {
        models[model] = true;
        return model;
    }

    Model upload(VAO vao, Material material) { return upload(new Model(vao, material)); }    
    Model upload(Mesh mesh, Material material) { return upload(upload(mesh), material); }

    Model upload()                             { return upload(new Model(null, null)); }    

    //-------------------------------------------------------------------------
    // Node buffer
    //-------------------------------------------------------------------------
    
    Node[] nodes;

    size_t length() { return nodes.length; }

    Node add(Node node) { nodes ~= node; return node; }
    void clear() { nodes.length = 0; }

    void remove(Node node)
    {
        auto i = countUntil(nodes, node);
        if(i != -1) nodes = std.algorithm.remove!(SwapStrategy.unstable)(nodes, i);
    }

    //-------------------------------------------------------------------------

    void draw(View cam)
    {
        if(!length) return;

        state.activate();
        loadView(cam);

        final switch(mode)
        {
            case Mode.unsorted: break;
            case Mode.front2back:
                sort!((a, b) => a.viewspace.bspdst2 < b.viewspace.bspdst2)(nodes);
                //sort!((a, b) => a.viewspace.bsp.z < b.viewspace.bsp.z)(nodes);
                break;
            case Mode.back2front:
                sort!((a, b) => a.viewspace.bspdst2 > b.viewspace.bspdst2)(nodes);
                //sort!((a, b) => a.viewspace.bsp.z > b.viewspace.bsp.z)(nodes);
                break;
        }

        foreach(node; nodes)
        {
            if(!node.model.material) continue;
            if(!node.model.vao) continue;

            render(node.transform, node.model.material, node.model.vao);
        }
    }
}

//*****************************************************************************
//
// BatchGroup: Work with multiple batches.
//
//*****************************************************************************

class BatchGroup
{
    Batch[] batches;
    
    //-------------------------------------------------------------------------

    Batch addbatch(Batch batch)
    {
        batches ~= batch;
        return batch;
    }

    Batch addbatch(Batch batch, Batch.Mode mode)
    {
        batches ~= new Batch(batch, mode);
        return batch;
    }

    Batch addbatch(gpu.State state, Batch.Mode = Batch.Mode.unsorted)
    {
        return addbatch(new Batch(state));
    }

    //-------------------------------------------------------------------------

    private Batch findModel(Model model)
    {
        foreach(batch; batches)
        {
            if(model in batch.models) return batch;
        }
        return null;
    }

    Node add(Node node) { findModel(node.model).add(node); return node; }

    //-------------------------------------------------------------------------

    private Batch findNode(Node node)
    {
        foreach(batch; batches)
        {
            if(countUntil(batch.nodes, node) != -1) return batch;
        }
        return null;
    }

    void remove(Node node) {
        auto batch = findNode(node);
        if(batch) batch.remove(node);
    }

    //-------------------------------------------------------------------------

    void clear()
    {
        foreach(batch; batches) batch.clear();
    }
    
    size_t length()
    {
        size_t l = 0;
        foreach(batch; batches) l += batch.length();
        return l;
    }
    
    Batch opIndex(int index) { return batches[index]; }
    
    //-------------------------------------------------------------------------

    void draw(View cam)
    {
        foreach(batch; batches)
        {
            batch.draw(cam);
        }
    }
}


