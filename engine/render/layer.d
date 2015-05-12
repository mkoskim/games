//*****************************************************************************
//
// Layer is a bunch of rendered objects.
//
// TO BE REWORKED! Layers are integrated to 'blitter' object, which combines
// shader control, layers and such together.
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
import engine.render.instance;
import engine.render.shaders.base;

//-----------------------------------------------------------------------------

class Layer
{
    Shader shader;

    View cam;
    bool[Instance] instances;

    auto length() { return instances.length; }

    //-------------------------------------------------------------------------

    this(Shader shader, View cam)
    {
        this.shader = shader;
        this.cam = cam;
    }

    this(Layer layer)
    {
        this(layer.shader, layer.cam);
    }

    //-------------------------------------------------------------------------

    Instance add(Instance instance) { instances[instance] = true; return instance; }
    void remove(Instance instance) { instances.remove(instance); }

    Instance add(vec3 pos) { return add(new Instance(pos)); }
    Instance add(vec3 pos, Shape shape) { return add(new Instance(pos, shape)); }

    Instance add(vec3 pos, Shader.VAO mesh, Material mat) { return add(new Instance(pos, mesh, mat)); }
    Instance add(vec3 pos, Shader.VAO mesh, vec4 color) { return add(new Instance(pos, mesh, new Material(color))); }
    Instance add(vec3 pos, Shader.VAO mesh, Texture tex) { return add(new Instance(pos, mesh, new Material(tex))); }

    Instance add(float x, float y) { return add(new Instance(vec3(x, y, 0))); }
    Instance add(float x, float y, Shape shape) { return add(new Instance(vec3(x, y, 0), shape)); }

    Instance add(float x, float y, Shader.VAO mesh, Material mat) { return add(new Instance(vec3(x, y, 0), mesh, mat)); }
    Instance add(float x, float y, Shader.VAO mesh, vec4 color) { return add(vec3(x, y, 0), mesh, color); }
    Instance add(float x, float y, Shader.VAO mesh, Texture tex) { return add(vec3(x, y, 0), mesh, tex); }

    //-------------------------------------------------------------------------

    Shader.VAO upload(Mesh mesh) { return shader.upload(mesh); }

    //-------------------------------------------------------------------------

    void draw()
    {
        shader.activate();

        foreach(instance; instances.keys) instance.render(shader, cam);
    }
}

