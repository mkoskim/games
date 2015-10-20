//*****************************************************************************
//
// Batch: The idea is that when nodes are collected from
// scene graph(s), they can be classified and thus moved to right batch.
//
//*****************************************************************************

module engine.render.pipeline.batch;

//-----------------------------------------------------------------------------

import engine.render.util;

import engine.render.types.transform;
import engine.render.types.mesh;
import engine.render.types.bounds;
import engine.render.types.material;
import engine.render.types.model;
import engine.render.types.node;
import engine.render.types.view;

import engine.render.pipeline.shader;
import engine.render.pipeline.state;

import engine.render.gpu.texture;

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

    this(State state, Mode mode = Mode.unsorted) {
        this.state = state;
        this.mode = mode;
    }

    this(Batch batch, Mode mode) { this(batch.state, mode); }
    this(Batch batch) { this(batch.state, batch.mode); }

    //-------------------------------------------------------------------------

    //static Batch Default2D() { return new Batch(State.Default2D()); }
    static Batch Solid3D() { return new Batch(State.Solid3D(), Mode.front2back); }
    static Batch Transparent3D() { return new Batch(State.Transparent3D(), Mode.back2front); }

    //-------------------------------------------------------------------------
    // Asset management
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

    Model upload(Shader.VAO vao, Material material) { return upload(new Model(vao, material)); }
    Model upload(Shader.VAO vao, Texture colormap)  { return upload(vao, new Material(colormap)); }
    Model upload(Shader.VAO vao, vec4 color)        { return upload(vao, new Material(color)); }    
    
    Model upload(Mesh mesh, Material material) { return upload(upload(mesh), material); }
    Model upload(Mesh mesh, Texture colormap)  { return upload(mesh, new Material(colormap)); }
    Model upload(Mesh mesh, vec4 color)        { return upload(mesh, new Material(color)); }    

    Model upload()                             { return upload(new Model(null, null)); }    

    //-------------------------------------------------------------------------
    // Bulk uploads
    //-------------------------------------------------------------------------

    Model[] upload(Mesh mesh, Material[] materials)
    {
        Model[] list;
        foreach(material; materials) {
            list ~= upload(upload(mesh), material);
        }
        return list;
    }

    Model[] upload(Shader.VAO vao, Bitmap[] colormaps)
    {
        Model[] list;
        foreach(colormap; Texture.Loader.Default(colormaps)) {
            list ~= upload(vao, colormap);
        }
        return list;
    }

    Model[] upload(Mesh mesh, Bitmap[] colormaps)
    {
        return upload(upload(mesh), colormaps);
    }

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

    Batch addbatch(Batch batch, Batch.Mode mode)
    {
        batches ~= new Batch(batch, mode);
        return batch;
    }

    Batch addbatch(State state, Batch.Mode = Batch.Mode.unsorted)
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
    
    //-------------------------------------------------------------------------

    void draw(View cam)
    {
        foreach(batch; batches)
        {
            batch.draw(cam);
        }
    }
}


