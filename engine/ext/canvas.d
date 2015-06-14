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

class Canvas
{
    State state;
    View cam;
    
    Shader.VAO unitbox;
    
    //-------------------------------------------------------------------------

    Shape[] shapes;

    void add(Shape shape) { shapes ~= shape; }

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
        foreach(shape; shapes) shape.draw(this, mat4.identity());
    }
}

//-----------------------------------------------------------------------------
// Shapes have dimensions (either innate, or calculated from content)
//-----------------------------------------------------------------------------

abstract class Shape
{
    this() { }

    abstract float width();
    abstract float height();

    final vec2 dimensions() { return vec2(width, height); }
    
    abstract void draw(Canvas canvas, mat4 transform);
}

//-----------------------------------------------------------------------------

class Box : Shape
{
    vec2 rect;
    Material mat;
        
    this(float w, float h, vec4 color)
    {
        super();
        this.rect = vec2(w, h);
        this.mat = new Material(color);
    }

    override float width() { return rect.x; }
    override float height() { return rect.y; }

    override void draw(Canvas canvas, mat4 local)
    {
        mat4 dim = mat4.identity().scale(width, height, 1);
        canvas.render(local * dim, mat, canvas.unitbox);
    }
}

//-----------------------------------------------------------------------------
// Positioning
//-----------------------------------------------------------------------------

class Position : Shape
{
    float x, y;
    Shape child;

    this(float x, float y, Shape child)
    {
        this.x = x;
        this.y = y;
        this.child = child;
    }

    override float width() { return child.width(); }
    override float height() { return child.height(); }

    override void draw(Canvas canvas, mat4 local)
    {
        mat4 m = Transform.matrix(x, y);
        child.draw(canvas, local * m);
    }
}

//-----------------------------------------------------------------------------
// Layouts
//-----------------------------------------------------------------------------

class HBox : Shape
{
    Shape[] shapes;
    
    void add(Shape shape) { shapes ~= shape; }
    
    this(Shape[] shapes...) {
        super();
        foreach(shape; shapes) add(shape);
    }

    override float width()
    {
        float w = 0;
        foreach(shape; shapes) w += shape.width();
        return w;
    }
    
    override float height()
    {
        float h = 0;
        foreach(shape; shapes) h = max(h, shape.height());
        return h;
    }

    override void draw(Canvas canvas, mat4 local)
    {
        vec2 cursor = vec2(0, 0);
        foreach(shape; shapes)
        {
            mat4 m = Transform.matrix(cursor.x, cursor.y);
            shape.draw(canvas, local * m);
            cursor.x += shape.width();
        }
    }
}

//*****************************************************************************
//*****************************************************************************

static if(0) class TextBox : Shape
{
    //-------------------------------------------------------------------------
    //
    //-------------------------------------------------------------------------

    this(float x, float y, string text, Font font_ = null)
    {
        super(x, y);

        if(!font_) {
            //font_ = Font.load("engine/stock/fonts/default.ttf", 12);
            font_ = Font.load("engine/stock/fonts/Courier Prime/Courier Prime.ttf", 12);
            //font_ = Font.load("usr/share/fonts/truetype/freefont/FreeMono.ttf", 12);
            //font_ = Font.load("usr/share/fonts/truetype/freefont/FreeMonoBold.ttf", 12);
            //font_ = Font.load("usr/share/fonts/truetype/freefont/FreeSans.ttf", 12);
            //font_ = Font.load("usr/share/fonts/truetype/freefont/FreeSerif.ttf", 12);
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

