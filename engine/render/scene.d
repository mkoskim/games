//*****************************************************************************
//
// This is temporary source file to restructure game engine rendering.
//
//*****************************************************************************

module engine.render.scene;

//-------------------------------------------------------------------------

import engine.render.util;

import engine.render.bone;
import engine.render.instance;
import engine.render.view;
import engine.render.light;

import engine.render.shaders.base;
import engine.render.shaders.defaults;
import engine.render.shaders.blanko: Blanko;

import engine.render.bound;
import engine.render.texture;
import engine.render.material;

import std.algorithm: sort, filter;

//-------------------------------------------------------------------------

class Scene
{
    //---------------------------------------------------------------------
    // Objects can be rendered with different shaders, e.g. some shaders
    // support animation, some do not. Each object in game world
    // "belongs" to specific shader.
    //---------------------------------------------------------------------

    Shader shader;
    bool[Instance] instances;

    Light light;

    auto length() { return instances.length; }

    bool useFrustumCulling = true;
    bool useSorting = true;

    //-------------------------------------------------------------------------

    this(Shader shader)
    {
        this.shader = shader;
    }

    this()
    {
        this(Default3D.create());
    }

    //-------------------------------------------------------------------------

    Instance add(Instance instance) { instances[instance] = true; return instance; }
    void remove(Instance instance) { instances.remove(instance); }

    //-------------------------------------------------------------------------

    Instance add(vec3 pos, Shader.VAO mesh, Material mat) { return add(new Instance(pos, mesh, mat)); }
    Instance add(vec3 pos, Shape shape) { return add(new Instance(null, pos, vec3(0, 0, 0), shape)); }
    Instance add(vec3 pos, vec3 rot, Shape shape) { return add(new Instance(null, pos, rot, shape)); }
    Instance add(Bone parent, Shape shape) { return add(new Instance(parent, shape)); }

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

