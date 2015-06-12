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

module engine.ext.canvas;

//-----------------------------------------------------------------------------

import engine.render.state;
import engine.render.view;
import engine.render.shaders.base;
import engine.render.transform;
import engine.render.material;
import gl3n.linalg;

import engine.ext.font;
import engine.ext.geom;

static import std.string;
import std.stdio;

//-----------------------------------------------------------------------------

abstract class ShapeGroup
{
    Shape[] childs;

    void add(Shape shape) { childs ~= shape; }
}

//-----------------------------------------------------------------------------

class Canvas : ShapeGroup
{
    State state;
    View cam;
    
    Shader.VAO unitbox;
    
    //-------------------------------------------------------------------------

    this(State state, View cam) {
        this.state = state;
        this.cam = cam;
        
        unitbox = state.shader.upload(rect(1, 1));
    }

    this() { this(State.Default2D(), Camera.topleft2D()); }

    //-------------------------------------------------------------------------

    void render(mat4 transform, Material material, Shader.VAO vao)
    {
        state.shader.loadMaterial(material);
        state.shader.render(transform, vao);
    }

    void draw()
    {
        state.activate();
        state.shader.loadView(cam);
        foreach(child; childs) child.draw(this, mat4.identity());
    }
}

//-----------------------------------------------------------------------------

abstract class Shape : ShapeGroup
{
    float x, y;

    this(float x, float y) {
        this.x = x;
        this.y = y;
    }
    
    void drawcontent(Canvas canvas, mat4 transform) { }
    
    final void draw(Canvas canvas, mat4 transform)
    {
        mat4 local = Transform.matrix(x, y) * transform;
        drawcontent(canvas, local);
        foreach(child; childs) child.draw(canvas, local);
    }
}

//-----------------------------------------------------------------------------

class Box : Shape
{
    float w, h;
    Material mat;
        
    this(float x, float y, float w, float h, Material mat)
    {
        super(x, y);
        this.w = w;
        this.h = h;
        this.mat = mat;
    }

    override void drawcontent(Canvas canvas, mat4 local)
    {
        mat4 dim = mat4.identity().scale(w, h, 1);
        canvas.render(local * dim, mat, canvas.unitbox);
    }
}

//*****************************************************************************
//*****************************************************************************

class TextBox : Shape
{
    //-------------------------------------------------------------------------
    //
    //-------------------------------------------------------------------------

    this(float x, float y, string text, Font font_ = null)
    {
        super(x, y);

        if(!font_) {
            font_ = Font.load("engine/stock/fonts/Courier Prime/Courier Prime.ttf", 12);
        }
        font = font_;

        foreach(line; std.string.split(text, "\n"))
        {
            foreach(i, s; std.string.split(line, "%"))
            {
                if(i & 1)
                {
                    if(s.length)
                    {
                        fields[s] = new Dynamic(s);
                        elems ~= fields[s];
                    }
                    else
                    {
                        elems ~= new Static("%");
                    }
                }
                else if(s.length)
                {
                    elems ~= new Static(s);
                }
            }
            elems ~= new Static("\n");
        }
    }

    ~this() { }

    //-------------------------------------------------------------------------
    //
    //-------------------------------------------------------------------------

    class Element
    {
        vec4 color;
        this() { color = vec4(1, 1, 1, 1); }
        abstract string content();
    }

    class Static : Element
    {
        string text;
        this(string s) { super(); text = s; }
        override string content() { return text; }
    }

    class Dynamic : Element
    {
        string value;
        this(string s) { super(); value = s; }
        override string content() { return value; }
    }

    //-------------------------------------------------------------------------
    //
    //-------------------------------------------------------------------------

    Dynamic[string] fields;
    Element[] elems;
    Font font;

    Dynamic opIndex(string name) { return fields[name]; }
    void opIndexAssign(string value, string name) { fields[name].value = value; }

    //-------------------------------------------------------------------------

    override void drawcontent(Canvas canvas, mat4 transform)
    {
        auto material = new Material();
        auto cursor = vec2(0, 0);
        int max_height = 0;
        
        foreach(elem; elems) {
            if(elem.content == "\n")
            {
                cursor.x = 0;
                cursor.y += max_height;
                max_height = 0;
            }
            else foreach(c; elem.content) {
                material.colormap = font.render(c);

                auto m = Transform.matrix(
                    vec3(cursor.x, cursor.y, 0),
                    vec3(0, 0, 0),
                    vec3(
                        material.colormap.width,
                        material.colormap.height,
                        0
                    )
                );

                canvas.render(transform * m, material, canvas.unitbox);
                cursor.x += material.colormap.width;
                max_height = max(max_height, material.colormap.height);
            }
        }
    }
}

