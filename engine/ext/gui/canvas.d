//*****************************************************************************
//
// Canvas stores objects that (actively) draw something: that is, objects
// are not drawn, but they draw. This is mainly intended for GUI purposes.
//
// This is part of sketching mechanisms to create GUI. It may lead to
// unpredicted directions when seeing how Canvas and rest of the rendering
// framework interferes to each other :)
//
// For my purposes, GUI should be usable with game controller.
//
//*****************************************************************************

module engine.ext.gui.canvas;

//-----------------------------------------------------------------------------

import engine.ext.gui.util;

import engine.render.state;
import engine.render.view;
import engine.render.shaders.base;
import engine.ext.geom;

//-----------------------------------------------------------------------------

class Canvas
{
    private
    {
        State state;
        View cam;
    
        Shader.VAO unitbox;
    }

    //-------------------------------------------------------------------------

    Widget[] widgets;

    void add(Widget widget) { widgets ~= widget; }

    //-------------------------------------------------------------------------

    this() { this(State.Default2D(), Camera.topleft2D()); }

    this(State state, View cam) {
        this.state = state;
        this.cam = cam;
        
        unitbox = state.shader.upload(rect(1, 1));
    }

    //-------------------------------------------------------------------------

    private void render(mat4 transform)
    {
        state.shader.render(transform, unitbox);
    }

    void render(mat4 transform, Material material)
    {
        state.shader.loadMaterial(material);
        render(transform);
    }

    void render(mat4 transform, vec4 color)
    {
        state.shader.loadMaterial(new Material(color));
        render(transform);
    }

    void render(mat4 transform, Texture texture)
    {
        state.shader.loadMaterial(new Material(texture));
        render(transform);
    }

    void render(mat4 transform, Texture texture, vec4 color)
    {
        state.shader.loadMaterial(new Material(texture), new Material.Modifier(color));
        render(transform);
    }

    //-------------------------------------------------------------------------

    void draw()
    {
        state.activate();
        state.shader.loadView(cam);
        foreach(widget; widgets) widget.draw(this, mat4.identity());
    }
}

