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
import engine.render.instance;
import engine.render.shaders.base;
import engine.render.shaders.defaults;

//*****************************************************************************
//
// Object storage
//
//*****************************************************************************

class InstanceGroup
{
    Shader shader;
    bool[Instance] instances;

    auto length() { return instances.length; }

    //-------------------------------------------------------------------------

    this(Shader shader) { this.shader = shader; }

    //-------------------------------------------------------------------------

    Shader.VAO upload(Mesh mesh) { return shader.upload(mesh); }

    //-------------------------------------------------------------------------

    Instance add(Instance instance) { instances[instance] = true; return instance; }
    void remove(Instance instance) { instances.remove(instance); }

    Instance add(vec3 pos) { return add(new Instance(pos)); }
    Instance add(vec3 pos, Shape shape) { return add(new Instance(pos, shape)); }
    Instance add(Bone parent, Shape shape) { return add(new Instance(parent, shape)); }

    Instance add(vec3 pos, Shader.VAO mesh, Material mat) { return add(new Instance(pos, mesh, mat)); }
    Instance add(vec3 pos, Shader.VAO mesh, vec4 color) { return add(new Instance(pos, mesh, new Material(color))); }
    Instance add(vec3 pos, Shader.VAO mesh, Texture tex) { return add(new Instance(pos, mesh, new Material(tex))); }

    Instance add(float x, float y) { return add(new Instance(vec3(x, y, 0))); }
    Instance add(float x, float y, Shape shape) { return add(new Instance(vec3(x, y, 0), shape)); }

    Instance add(float x, float y, Shader.VAO mesh, Material mat) { return add(new Instance(vec3(x, y, 0), mesh, mat)); }
    Instance add(float x, float y, Shader.VAO mesh, vec4 color) { return add(vec3(x, y, 0), mesh, color); }
    Instance add(float x, float y, Shader.VAO mesh, Texture tex) { return add(vec3(x, y, 0), mesh, tex); }
}

//*****************************************************************************
//
// Object sorting & filtering
//
//*****************************************************************************

import std.algorithm;

class Batch
{
    Instance[] instances;

    this() { }
    ~this() { }

    void add(InstanceGroup group)
    {
        foreach(k, v; group.instances) instances ~= k;
    }

    void filter(View cam)
    {
    }

    void front2back() {
        sort!((a, b) => a.viewspace.bspdst2 < b.viewspace.bspdst2)(instances);
    }
    void back2front() {
        sort!((a, b) => a.viewspace.bspdst2 > b.viewspace.bspdst2)(instances);
    }
}

//*****************************************************************************
//
//
//
//*****************************************************************************

class Layer : InstanceGroup
{
    View cam;
    
    //-------------------------------------------------------------------------

    this(Shader shader, View cam)
    {
        super(shader);
        this.cam = cam;
    }

    this(Layer layer)
    {
        this(layer.shader, layer.cam);
    }

    //-------------------------------------------------------------------------

    void draw()
    {
        shader.activate();
        shader.loadView(cam);

        foreach(instance; instances.keys) instance.render(shader);
    }
}

//*****************************************************************************
//
//
//
//*****************************************************************************

class Scene : InstanceGroup
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

        Instance[] drawlist;

        if(useFrustumCulling) {
            foreach(object; instances.keys) {
                object.project(cam);
                if(!object.viewspace.infrustum) continue;
                drawlist ~= object;
            }
        } else {
            drawlist = instances.keys;
        }

        //---------------------------------------------------------------------

        shader.activate();
        shader.loadView(cam);
        
        if(light) shader.light(light);

        if(useSorting) {
            auto front2back(Instance[] drawlist) {
                return sort!((a, b) => a.viewspace.bspdst2 < b.viewspace.bspdst2)(drawlist);
            }
            auto back2front(Instance[] drawlist) {
                return sort!((a, b) => a.viewspace.bspdst2 > b.viewspace.bspdst2)(drawlist);
            }

            foreach(object; front2back(drawlist)) {
                object.render(shader);
                perf.drawed++;
            }
        } else {
            foreach(object; drawlist) {
                object.render(shader);
                perf.drawed++;
            }
        }
    }

    //-------------------------------------------------------------------------

    struct Performance
    {
        int drawed;

        void reset() { drawed = 0; }
    }
    Performance perf;
}


