//*****************************************************************************
//
// Boxes
//
//*****************************************************************************

module engine.ext.gui.box;

import engine.ext.gui.util;
import engine.ext.gui.widget;

//-----------------------------------------------------------------------------
// TODO: "Box" is pretty static thing, we should separate "leafs" from
// groups, so that we can use these kind of classes to draw different things.
//-----------------------------------------------------------------------------

class Space : Widget
{
    vec2 dim;

    this(vec2 dim) { this.dim = dim; }
    this(float w, float h) { this(vec2(w, h)); }

    override float width() { return dim.x; }
    override float height() { return dim.y; }

    void stretch(float w, float h)
    {
        dim.x = w;
        dim.y = h;
    }

    override void draw(Canvas, vec2, vec2) { }

    static Space H(float s) { return new Space(s, 0); }
    static Space V(float s) { return new Space(0, s); }
}

class Box : Space
{
    Texture tex;

    //-------------------------------------------------------------------------

    this(float w, float h) { super(w, h); }
    
    this(vec4 color, float w, float h)
    {
        this(w, h);
        this.tex = new Texture(color);
    }

    this(Texture texture, float w, float h)
    {
        this(w, h);
        this.tex = texture;
        //texture.filtering(GL_NEAREST, GL_NEAREST);
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

    override void draw(Canvas canvas, vec2 offset, vec2)
    {
        canvas.render(offset, size(), tex);
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

