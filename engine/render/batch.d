//*****************************************************************************
//
// Batch: The idea is that when nodes are collected from
// scene graph(s), they can be classified and thus moved to right batch.
//
//*****************************************************************************

module engine.render.batch;

//-----------------------------------------------------------------------------

import engine.render.util;

import engine.render.shaders.base;
import engine.render.state;

import engine.render.transform;
import engine.render.mesh;
import engine.render.bound;
import engine.render.texture;
import engine.render.material;
import engine.render.model;
import engine.render.node;
import engine.render.view;

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

class Batch
{
    State state;

    enum Mode { unsorted, front2back, back2front };
    Mode mode;
    
    this(State state, Mode mode = Mode.unsorted)
    {
        this.state = state;
        this.mode = mode;
    }

    this(Batch batch, Mode mode) { this(batch.state, mode); }
    this(Batch batch) { this(batch, batch.mode); }

    //-------------------------------------------------------------------------

    static Batch Default2D() { return new Batch(State.Default2D()); }

    static Batch Solid3D() { return new Batch(State.Solid3D(), Mode.front2back); }
    static Batch Transparent3D() { return new Batch(State.Transparent3D(), Mode.back2front); }

    //-------------------------------------------------------------------------
    // TODO: Maybe VAO cache is better located in shader itself? Or some sort
    // of "shader bank", shared with all compatible shaders. For cleaning up,
    // it would be better that this information would be in some sort of
    // manager object, which is destroyed when scene is destroyed.
    //
    // Maybe, the system works so that batch itself is destroyed, when scene
    // is destroyed. Which ever looks the nicest solution.
    //
    //-------------------------------------------------------------------------
    
    Shader.VAO[Mesh] meshes;
    
    Shader.VAO upload(Mesh mesh)
    {
        if(!(mesh in meshes))
        {
            meshes[mesh] = state.shader.upload(mesh);
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

    Model upload(Mesh mesh, Material material) { return upload(new Model(upload(mesh), material)); }
    Model upload(Mesh mesh, Texture colormap)  { return upload(new Model(upload(mesh), new Material(colormap))); }
    Model upload(Mesh mesh, vec4 color)        { return upload(new Model(upload(mesh), new Material(color))); }    

    Model upload()                             { return upload(new Model(null, null)); }    

    //-------------------------------------------------------------------------
    // Nodes collected for rendering
    //-------------------------------------------------------------------------
    
    Node[] nodes;    

    ulong length() { return nodes.length; }

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
        if(!nodes.length) return;

        state.activate();
        state.shader.loadView(cam);

        final switch(mode)
        {
            case Mode.unsorted: break;
            case Mode.front2back:
                sort!((a, b) => a.viewspace.bspdst2 < b.viewspace.bspdst2)(nodes);
                break;
            case Mode.back2front:
                sort!((a, b) => a.viewspace.bspdst2 > b.viewspace.bspdst2)(nodes);
                break;
        }
        
        foreach(node; nodes)
        {
            if(!node.model.material) continue;
            if(!node.model.vao) continue;

            state.shader.render(node.transform, node.model.material, node.model.vao);
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

    Batch addbatch(State state)
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
    
    ulong length()
    {
        ulong l = 0;
        foreach(batch; batches) l += batch.length();
        return l;
    }
    
    //-------------------------------------------------------------------------

    void draw(View cam)
    {
        foreach(batch; batches)
        {
            batch.draw(cam);
        }
    }
}


