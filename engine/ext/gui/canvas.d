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

import engine.render.state;
import engine.render.view;
import engine.render.shaders.base;
import engine.render.transform;
import engine.render.material;

import gl3n.linalg;
import derelict.opengl3.gl3;

public import engine.render.texture: Texture;
public import engine.ext.bitmap: Bitmap;

import engine.game.instance;

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

    //-------------------------------------------------------------------------

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
// TODO: "Box" is pretty static thing, we should separate "leafs" from
// groups, so that we can use these kind of classes to draw different things.
//-----------------------------------------------------------------------------

class Box : Shape
{
    vec2 dim;
    Texture tex;
        
    //-------------------------------------------------------------------------

    this(vec4 color, float w, float h)
    {
        super();
        this.dim = vec2(w, h);
        this.tex = new Texture(color);
    }

    this(Texture texture, float w, float h)
    {
        this.dim = vec2(w, h);
        this.tex = texture;
        texture.filtering(GL_NEAREST, GL_NEAREST);
    }
    
    this(Texture texture)
    {
        this(texture, texture.width, texture.height);
    }

    this(Bitmap bitmap, float w, float h)
    {
        this(new Texture(bitmap), w, h);
    }
    
    this(Bitmap bitmap)
    {
        this(new Texture(bitmap));
    }

    //-------------------------------------------------------------------------

    override float width() { return dim.x; }
    override float height() { return dim.y; }

    void stretch(float w, float h)
    {
        dim.x = w;
        dim.y = h;
    }

    override void draw(Canvas canvas, mat4 local)
    {
        canvas.render(local * mat4.identity().scale(width, height, 1), tex);
    }

    //-------------------------------------------------------------------------

    static Box[][] create(Texture[][] textures)
    {
        Box[][] grid;
        
        foreach(row; textures) {
            Box[] line;
            foreach(col; row) {
                line ~= new Box(col);
            }
            grid ~= line;
        }
        return grid;
    }
}

//-----------------------------------------------------------------------------

abstract class GridContainer : Shape
{
    struct COLUMN {
        float x; float width;
        this(float x = 0, float w = 0)
        {
            this.x = x;
            this.width = w;
        }
    }
    
    struct ROW {
        float y; float height;
        this(float y = 0, float h = 0)
        {
            this.y = y;
            this.height = h;
        }
    }

    COLUMN[] cols;
    ROW[] rows;

    class Bin : Shape
    {
        GridContainer parent;
        int col, row;
        Shape child;

        this(GridContainer parent, int col, int row, Shape child) {
            this.parent = parent;
            this.col = col;
            this.row = row;
            this.child = child;
            
            parent.cols[col].width = max(parent.cols[col].width, child.width);
            parent.rows[row].height = max(parent.rows[row].height, child.height);
        }

        vec2 pos() { return vec2(parent.cols[col].x, parent.rows[row].y); }
        
        override float width() { return parent.cols[col].width; }
        override float height() { return parent.rows[row].height; }

        override void draw(Canvas canvas, mat4 local)
        {
            mat4 m = Transform.matrix(pos().x, pos().y);
            child.draw(canvas, local * m);
        }
    }

    Bin[] childs;

    void add(int col, int row, Shape shape)
    {
        if(cols.length <= col) cols ~= COLUMN(0, 0);
        if(rows.length <= row) rows ~= ROW(0, 0);
        childs ~= new Bin(this, col, row, shape);        
    }

    protected void calcdim()
    {
        cols[0].x = 0;
        foreach(i; 1 .. cols.length) cols[i].x = cols[i-1].x + cols[i-1].width;
        rows[0].y = 0;
        foreach(i; 1 .. rows.length) rows[i].y = rows[i-1].y + rows[i-1].height;
    }

    override float width() {
        ulong last = cols.length - 1;
        return cols[last].x + cols[last].width;
    }

    override float height() {
        ulong last = rows.length - 1;
        return rows[last].y + rows[last].height;
    }
    
    override void draw(Canvas canvas, mat4 local)
    {
        foreach(bin; childs) bin.draw(canvas, local);
    }
}

//-----------------------------------------------------------------------------

class Grid : GridContainer
{
    this(Shape[] shapes...) {
        super();

        int col = 0, row = 0;
        foreach(shape; shapes) {
            if(shape is null) {
                col = 0;
                row++;
            }
            else {
                add(col, row, shape);
                col++;
            }
        }
        calcdim();
    }
}

//-----------------------------------------------------------------------------

class Frame : GridContainer
{
    Shape child;
    
    this(Texture[][] textures, Shape child)
    {
        super();
    
        this.child = child;

        auto boxes = Box.create(textures);

        foreach(row; 0 .. 3) foreach(col; 0 .. 3)
        {
            add(col, row, boxes[row][col]);
        }

        add(1, 1, child);

        foreach(row; 0 .. 3) foreach(col; 0 .. 3)
        {
            boxes[row][col].stretch(cols[col].width, rows[row].height);
        }
        calcdim();
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

class Anchor : Shape
{
    vec2 anchor;
    Shape child;

    this(vec2 anchor, Shape child)
    {
        this.anchor = anchor;
        this.child = child;
    }
    
    override float width() { return child.width(); }
    override float height() { return child.height(); }

    override void draw(Canvas canvas, mat4 local)
    {
        float x, y;

        x = anchor.x * (screen.width - child.width);
        y = anchor.y * (screen.height - child.height);

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

