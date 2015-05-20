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

module engine.render.layer;

//-----------------------------------------------------------------------------

import engine.render.util;
import engine.render.view;
import engine.render.bone;
import engine.render.mesh;
import engine.render.texture;
import engine.render.material;
import engine.render.light;
import engine.render.model;
import engine.render.batch;

//import engine.render.shaders.base;
//import engine.render.shaders.defaults;

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

    Node add(Node node) { return _add(node); }
    Node add(vec3 pos) { return _add(new Node(pos)); }
    Node add(vec3 pos, Model model) { return _add(new Node(pos, model)); }
    Node add(Bone parent, Model model) { return _add(new Node(parent, model)); }

    Node add(float x, float y) { return _add(new Node(vec3(x, y, 0))); }
    Node add(float x, float y, Model model) { return _add(new Node(vec3(x, y, 0), model)); }

    /*
    Node add(vec3 pos, Shader.VAO mesh, Material mat) { return add(new Node(pos, mesh, mat)); }
    Node add(vec3 pos, Shader.VAO mesh, vec4 color) { return add(new Node(pos, mesh, new Material(color))); }
    Node add(vec3 pos, Shader.VAO mesh, Texture tex) { return add(new Node(pos, mesh, new Material(tex))); }

    Node add(float x, float y, Shader.VAO mesh, Material mat) { return add(new Node(vec3(x, y, 0), mesh, mat)); }
    Node add(float x, float y, Shader.VAO mesh, vec4 color) { return add(vec3(x, y, 0), mesh, color); }
    Node add(float x, float y, Shader.VAO mesh, Texture tex) { return add(vec3(x, y, 0), mesh, tex); }
    */
}

//*****************************************************************************
//
// Direct storage: stores nodes directly to batches, and renders them in
// order which batches are created.
//
//*****************************************************************************

class DirectRender : NodeGroup
{
    RenderState rs;
    View cam;
    Light light;
    BatchGroup batches;
    
    //-------------------------------------------------------------------------

    this(View cam, RenderState rs)
    {
        this.cam = cam;
        this.rs = rs;
        this.batches = new BatchGroup();
    }

    //-------------------------------------------------------------------------

    override Node _add(Node node) { batches.add(node); return node; }
    override void remove(Node node) { batches.remove(node); }    

    //-------------------------------------------------------------------------

    Batch addbatch() { return batches.addbatch(new Batch(rs)); }

    //-------------------------------------------------------------------------

    void draw()
    {
        // TODO: Hack! Design light subsystem
        rs.activate();    
        if(light) rs.shader.light(light);
        
        batches.draw(cam);
    }
}

//*****************************************************************************
//
// Collectable rendering: Models (Mesh + Material) are separated from
// Nodes (Model + transform).
//
//*****************************************************************************

abstract class CollectableNodeGroup : NodeGroup
{
    abstract void collect(View cam, BatchGroup batches);
}

//-----------------------------------------------------------------------------
// Define separate Node storage
//-----------------------------------------------------------------------------

class BasicNodeGroup : CollectableNodeGroup
{
    bool[Node] nodes;

    ulong length() { return nodes.length; }
    
    override Node _add(Node node) { nodes[node] = true; return node; }
    override void remove(Node node) { nodes.remove(node); }

    override void collect(View cam, BatchGroup batches)
    {
        foreach(node, _; nodes) {
            node.project(cam);
            if(!node.viewspace.infrustum) continue;
            batches.add(node);
        }
    }
}

/*
import std.algorithm;

class Batch
{
    Node[] nodes;

    auto length() { return nodes.length; }

    void add(Node node) { nodes ~= node; }

    void front2back() {
        sort!((a, b) => a.viewspace.bspdst2 < b.viewspace.bspdst2)(nodes);
    }
    void back2front() {
        sort!((a, b) => a.viewspace.bspdst2 > b.viewspace.bspdst2)(nodes);
    }

    void draw(Shader shader)
    {
        foreach(node; nodes) node.render(shader);
    }
}
*/

//*****************************************************************************
//
//
//
//*****************************************************************************

class xScene : NodeGroup
{
static if(0)
{
    Light light;

    bool useFrustumCulling = true;
    bool useSorting = true;

    this(Shader shader) { super(shader); }
    this() { this(Default3D.create()); }

    //-------------------------------------------------------------------------

    void draw(View cam)
    {
        perf.reset();

        //---------------------------------------------------------------------

        Batch batch = new Batch();

        if(useFrustumCulling) {
            foreach(node, _; nodes) {
                node.project(cam);
                if(!node.viewspace.infrustum) continue;
                batch.add(node);
            }
        } else {
            batch.nodes = nodes.keys;
        }

        //---------------------------------------------------------------------

        if(useSorting) batch.front2back();
        
        //---------------------------------------------------------------------

        shader.activate();
        shader.loadView(cam);
        
        if(light) shader.light(light);

        batch.draw(shader);
        perf.drawed += batch.length();
    }

    //-------------------------------------------------------------------------

    struct Performance
    {
        int drawed;

        void reset() { drawed = 0; }
    }
    Performance perf;
}
}


