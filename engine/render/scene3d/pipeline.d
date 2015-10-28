//*****************************************************************************
//
// Rendering pipeline
//
//*****************************************************************************

module engine.render.scene3d.pipeline;

import engine.render.util;

import gpu =
    engine.render.gpu.state,
    engine.render.gpu.shader;    

import engine.game.fiber;
import engine.render.scene3d.types.transform;
import engine.render.scene3d.types.material;
import engine.render.loader.mesh;
import engine.render.scene3d.types.model;
import engine.render.scene3d.types.node;
import engine.render.scene3d.types.view;
import engine.render.scene3d.types.light;
import engine.render.scene3d.batch;
//import engine.render.scene3d.layer;

import feeder = engine.render.scene3d.feeder;

//*****************************************************************************
//
// Low level interface. User can store custom shaders and states to
// groups for later use, if needed. The main interface is BatchGroup, which
// contains batches for specific shaders (with render state).
//
//*****************************************************************************

class ShaderGroup 
{
    gpu.Shader[string] lookup;
    
    gpu.Shader add(string name, gpu.Shader shader)
    {
        lookup[name] = shader;
        return shader;
    }
    
    gpu.Shader get(string name) { return lookup[name]; }
    gpu.Shader opIndex(string name) { return get(name); }
    gpu.Shader opCall(string name) { return get(name); }

    //-------------------------------------------------------------------------

    gpu.Shader Default3D(string name) {
        return add(name, feeder.Shader.Default3D());
    }
    gpu.Shader Flat3D(string name) {
        return add(name, feeder.Shader.Flat3D());
    }
}

//-----------------------------------------------------------------------------

class StateGroup
{
    gpu.State[string] lookup;

    gpu.State add(string name, gpu.State state)
    {
        lookup[name] = state;
        return state;
    }

    gpu.State get(string name) { return lookup[name]; }
    gpu.State opIndex(string name) { return get(name); }
    gpu.State opCall(string name) { return get(name); }

    //-------------------------------------------------------------------------

    gpu.State Solid3D(string name, gpu.Shader shader)
    {
        return add(name, feeder.State.Solid3D(shader));
    }

    gpu.State Transparent3D(string name, gpu.Shader shader)
    {
        return add(name, feeder.State.Transparent3D(shader));
    }
}

//-----------------------------------------------------------------------------

class BatchGroup
{
    Batch[] batches;

    //-------------------------------------------------------------------------

    Batch add(Batch batch)
    {
        batches ~= batch;
        return batch;
    }

    Batch add(gpu.State state) { return add(new Batch(state)); }

    //-------------------------------------------------------------------------
    // Lookup table for named batches
    //-------------------------------------------------------------------------

    Batch[string] lookup;

    Batch get(string name) { return lookup[name]; }
    Batch opIndex(string name) { return get(name); }
    Batch opCall(string name) { return get(name); }
    
    Batch add(string name, Batch batch)
    {
        lookup[name] = add(batch);
        return get(name);
    }

    Batch add(string name, gpu.State state)
    {
        lookup[name] = add(state);
        return get(name);
    }
    
    //-------------------------------------------------------------------------

    void clear()
    {
        foreach(batch; batches) batch.clear();
    }

    void draw(View cam, Light light)
    {
        foreach(batch; batches) batch.draw(cam, light);
    }
}

//*****************************************************************************
//
// Node groups contain nodes which are fetched to batches at the beginning
// of rendering.
//
//*****************************************************************************

class NodeSource
{
    bool[Node] nodes;

    size_t length() { return nodes.length; }

    this() { }
    
    Node add(Node node) { nodes[node] = true; return node; }
    void remove(Node node) { nodes.remove(node); }

    //-------------------------------------------------------------------------
    // By default, we add immovable objects, as guess is that they dominate
    // scenes. BTW, immovable node is not necessarily that immovable, it may
    // contain skeleton - which can, in addition to deform mesh, also move
    // the mesh around...
    //-------------------------------------------------------------------------

    Node add(Transform transform, Model model) { return add(new Node(transform, model)); }
    Node add(vec3 pos, Model model) { return add(Grip.fixed(pos), model); }
    Node add(float x, float y, float z, Model model) { return add(Grip.fixed(x, y, z), model); }
    Node add(float x, float y, Model model) { return add(Grip.fixed(x, y), model); }

    void clear() { foreach(key; nodes.keys) nodes.remove(key); }

    void collect(View cam)
    {
        foreach(node, _; nodes) {
            node.project(cam);
            if(!node.viewspace.infrustum) continue;
            (cast(Batch)node.model.vao.target).add(node);
        }
    }
}

//-----------------------------------------------------------------------------

class NodeGroup
{
    NodeSource[string] nodes;

    NodeSource add(string name, NodeSource source) {
        nodes[name] = source;
        return source;
    }    
    NodeSource add(string name) { return add(name, new NodeSource()); }
    
    NodeSource get(string name) { return nodes[name]; }
    NodeSource opIndex(string name) { return get(name); }
    NodeSource opCall(string name) { return get(name); }

    void collect(View cam) {
        foreach(source; nodes.values) source.collect(cam);
    }
}
//*****************************************************************************
//
// Asset management
//
//*****************************************************************************

class Asset
{
    Model[string] models;

    Mesh[string] meshes;
    Material[string] materials;
    Batch.VAO[Mesh] shapes;

    //-------------------------------------------------------------------------

    Material upload(string name, Material material)
    {
        materials[name] = material;
        return material;
    }

    Mesh upload(string name, Mesh mesh)
    {
        meshes[name] = mesh;
        return mesh;
    }

    Batch.VAO upload(Batch target, Mesh mesh) {
        if(mesh !in shapes) shapes[mesh] = target.upload(mesh);
        return shapes[mesh];
    }

    //-------------------------------------------------------------------------

    Model upload(string name, Model model)
    {
        if(name) models[name] = model;
        return model;
    }
    
    Model upload(string name, Batch.VAO vao, Material material)
    {
        return upload(name, new Model(vao, material));
    }

    Model upload(string name, Batch.VAO vao, string material)
    {
        return upload(name, vao, materials[material]);
    }

    Model upload(string name, Batch target, Mesh mesh, Material material)
    {
        return upload(name, upload(target, mesh), material);
    }

    Model upload(string name, Batch target, Mesh mesh, string material)
    {
        return upload(name, upload(target, mesh), materials[material]);
    }

    Model upload(string name, Batch target, string mesh, string material)
    {
        return upload(name, target, meshes[mesh], materials[material]);
    }

    //-------------------------------------------------------------------------

    Model get(string name) { return models[name]; }
    Model opIndex(string name) { return get(name); }
    Model opCall(string name) { return get(name); }
}

class AssetGroup
{
    Asset[string] assets;
    Material.Loader material = new Material.Loader();
    
    Asset add(string name, Asset asset) {
        assets[name] = asset;
        return asset;
    }
    Asset add(string name) { return add(name, new Asset()); }

    Asset get(string name) { return assets[name]; }
    Asset opIndex(string name) { return get(name); }
    Asset opCall(string name) { return get(name); }

    void remove(string name) { assets.remove(name); }
}

//*****************************************************************************
//
//
//*****************************************************************************

class Pipeline
{
    ShaderGroup shaders = new ShaderGroup();
    StateGroup  states  = new StateGroup();
    BatchGroup  batches = new BatchGroup();

    //-------------------------------------------------------------------------

    AssetGroup assets = new AssetGroup();
    NodeGroup nodes = new NodeGroup();

    //-------------------------------------------------------------------------

    this()
    {
    }

    //-------------------------------------------------------------------------

    View cam;
    Light light;

    FiberQueue actors = new FiberQueue();

    //-------------------------------------------------------------------------

    void draw()
    {
        batches.clear();
        nodes.collect(cam);
        batches.draw(cam, light);
    }
}

