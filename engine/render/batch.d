//*****************************************************************************
//
// Batch: The idea here is to encapsulate OpenGL settings behind
// a state block. Also, the idea is that when nodes are collected from
// scene graph(s), they can be classified and thus moved to right batch.
//
//*****************************************************************************

module engine.render.batch;

//-----------------------------------------------------------------------------

import engine.render.util;

import engine.render.shaders.base;
import engine.render.shaders.defaults;

import engine.render.bone;
import engine.render.mesh;
import engine.render.bound;
import engine.render.texture;
import engine.render.material;
import engine.render.model;
import engine.render.view;

//*****************************************************************************
//
// RenderState to hold OpenGL render settings
//
//*****************************************************************************

class RenderState
{
    Shader shader;

    bool[GLenum] enable;    // glEnable / glDisable

    //-------------------------------------------------------------------------

    this(Shader shader) { this.shader = shader; }
    
    //-------------------------------------------------------------------------
    
    private static RenderState active = null;
        
    final void activate()
    {
        if(active != this)
        {
            apply();
            active = this;
        }
    }

    //-------------------------------------------------------------------------
    
    protected void apply()
    {
        writeln("RenderState.apply: ", this);

        shader.activate();

        foreach(k, v; enable)
        {
            if(v) checkgl!glEnable(k); else checkgl!glDisable(k);
        }

        //glPolygonMode(GL_FRONT, fill ? GL_FILL : GL_LINE);
    }
}

//-----------------------------------------------------------------------------

class RenderState2D : RenderState
{
    this(Shader shader)
    {
        super(shader);
        
        enable[GL_CULL_FACE] = false;
        enable[GL_DEPTH_TEST] = false;
        
        enable[GL_BLEND] = true;
    }

    this() { this(Default2D.create()); }
    
    //-------------------------------------------------------------------------

    override void apply()
    {
        super.apply();

        checkgl!glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
}

//-----------------------------------------------------------------------------

class RenderState3D : RenderState
{
    this(Shader shader)
    {
        super(shader);

        enable[GL_CULL_FACE] = true;
        enable[GL_DEPTH_TEST] = true;
        
        enable[GL_BLEND] = false;
    }

    this() { this(Default3D.create()); }

    override void apply()
    {
        super.apply();

        checkgl!glFrontFace(GL_CCW);
    }
}

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
    RenderState rs;
    
    this(RenderState rs)
    {
        this.rs = rs;
    }

    //-------------------------------------------------------------------------
    // TODO: Maybe VAO cache is better located in shader itself? Or some sort
    // of "shader bank", shared with all compatible shaders.
    //-------------------------------------------------------------------------
    
    Shader.VAO[Mesh] meshes;
    
    Shader.VAO upload(Mesh mesh)
    {
        if(!(mesh in meshes))
        {
            meshes[mesh] = rs.shader.upload(mesh);
        }
        return meshes[mesh];
    }

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

    bool[Node] nodes;    

    ulong length() { return nodes.length; }

    Node add(Node node) { nodes[node] = true; return node; }
    void remove(Node node) { nodes.remove(node); }
    void clear() { foreach(node, _; nodes) remove(node); }
    bool has(Model model) { return (model in models) != null; }
    
    //-------------------------------------------------------------------------
    
    void draw(View cam)
    {
        rs.activate();
        rs.shader.loadView(cam);
        foreach(node, _; nodes)
        {
            if(!node.model.material) continue;
            if(!node.model.vao) continue;

            rs.shader.render(node.grip, node.model.material, node.model.vao);
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

    //-------------------------------------------------------------------------

    private Batch findModel(Model model)
    {
        foreach(batch; batches)
        {
            if(model in batch.models) return batch;
        }
        return null;
    }

    private Batch findNode(Node node)
    {
        foreach(batch; batches)
        {
            if(node in batch.nodes) return batch;
        }
        return null;
    }

    //-------------------------------------------------------------------------

    Node add(Node node) { findModel(node.model).add(node); return node; }
    void remove(Node node) { findNode(node).remove(node); }
    
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


