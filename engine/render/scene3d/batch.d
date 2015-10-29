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

import gpu = 
    engine.render.gpu.state,
    engine.render.gpu.shader;

import engine.render.gpu.texture;

import engine.render.scene3d.types.material;
import engine.render.scene3d.types.model;
import engine.render.scene3d.types.node;
import engine.render.scene3d.types.view;
import engine.render.scene3d.types.light;

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
    bool enabled = true;

    this(gpu.State state) { super(state); }
    this(Batch batch) { this(batch.state); }

    //-------------------------------------------------------------------------

    override VAO upload(Mesh mesh) {
        return super.upload(mesh);
    }

    Model upload(VAO vao, Material material) {
        return new Model(vao, material);
    }

    Model upload(Mesh mesh, Material material) {
        return upload(upload(mesh), material);
    }

    //-------------------------------------------------------------------------
    // Node buffer
    //-------------------------------------------------------------------------
    
    Node[] nodes;

    size_t length() { return nodes.length; }

    Node add(Node node) { nodes ~= node; return node; }
    void clear() { nodes.length = 0; }

    //-------------------------------------------------------------------------

    void draw(View cam, Light light)
    {
        if(!length) return;
        if(!enabled) return;

        state.activate();
        loadView(cam);
        loadLight(light);

        final switch(state.mode)
        {
            case gpu.State.Mode.unsorted: break;
            case gpu.State.Mode.front2back:
                sort!((a, b) => a.viewspace.bspdst2 < b.viewspace.bspdst2)(nodes);
                //sort!((a, b) => a.viewspace.bsp.z < b.viewspace.bsp.z)(nodes);
                break;
            case gpu.State.Mode.back2front:
                sort!((a, b) => a.viewspace.bspdst2 > b.viewspace.bspdst2)(nodes);
                //sort!((a, b) => a.viewspace.bsp.z > b.viewspace.bsp.z)(nodes);
                break;
        }

        foreach(node; nodes)
        {
            if(!node.model) continue;
            if(!node.model.material) continue;
            if(!node.model.vao) continue;

            render(node.transform, node.model.material, node.model.vao);
        }
    }
}

