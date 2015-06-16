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

import engine.game.instance;

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

    void add(Widget widget)         { widgets ~= widget; }
    void add(Widget[] widgets)      { foreach(widget; widgets) add(widget); }
    void add(Widget[] widgets...)   { foreach(widget; widgets) add(widget); }
    
    //-------------------------------------------------------------------------

    this() { this(State.Default2D(), Camera.topleft2D()); }

    this(State state, View cam) {
        this.state = state;
        this.cam = cam;
        
        unitbox = state.shader.upload(rect(1, 1));
    }

    //-------------------------------------------------------------------------

    private void render(vec2 offset, vec2 size)
    {
        mat4 transform = mat4.identity().scale(size.x, size.y, 1).translate(offset.x, offset.y, 0);
        state.shader.render(transform, unitbox);
    }

    void render(vec2 offset, vec2 size, Material material)
    {
        state.shader.loadMaterial(material);
        render(offset, size);
    }

    void render(vec2 offset, vec2 size, vec4 color)
    {
        state.shader.loadMaterial(new Material(color));
        render(offset, size);
    }

    void render(vec2 offset, vec2 size, Texture texture)
    {
        state.shader.loadMaterial(new Material(texture));
        render(offset, size);
    }

    void render(vec2 offset, vec2 size, Texture texture, vec4 color)
    {
        state.shader.loadMaterial(new Material(texture), new Material.Modifier(color));
        render(offset, size);
    }

    //-------------------------------------------------------------------------

    void draw()
    {
        state.activate();
        state.shader.loadView(cam);
        foreach(widget; widgets) {
            widget.draw(
                this,
                vec2(0, 0),
                vec2(screen.width, screen.height)
            );
        }
    }
}

