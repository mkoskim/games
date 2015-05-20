//*****************************************************************************
//
// Texts - and fonts
//
// Text blitting is more like a layout engine.
//
//*****************************************************************************

module engine.ext.text;

//-----------------------------------------------------------------------------

import engine.util;
import blob = engine.blob;
import engine.render.texture;
import engine.render.material;
import engine.render.model;
import engine.render.view;
import engine.render.bone;
import engine.render.layer;
import engine.render.shaders.base;
import engine.ext.geom;

static import std.string;

import std.algorithm: max;

//-----------------------------------------------------------------------------

class TTFError : Exception
{
    this(string msg) { super(msg); }
}

//*****************************************************************************
//*****************************************************************************

//-----------------------------------------------------------------------------
//
// TODO: TextBox is currently Node, so that it can be added to (HUD)
// Layer (Layer objects accept only Nodes). To render glyphs, TextBox
// modifies its position and dimensions, and feeds itself to Shader.
//
// This is a bit problematic approach. It would be great to figure out
// a better way.
//
//-----------------------------------------------------------------------------

class TextBox
{
static if(0)
{
    //-------------------------------------------------------------------------
    //
    //-------------------------------------------------------------------------

    this(Layer layer, float x, float y, string text, Font font_ = null)
    {
        //---------------------------------------------------------------------

        if(!font_)
        {
            font_ = Font.load("engine/stock/fonts/Courier Prime/Courier Prime.ttf", 12);
        }
        font = font_;

        //---------------------------------------------------------------------

        if(!(layer.shader in unitbox))
        {
            unitbox[layer.shader] = layer.shader.upload(rect(1, 1));
        }

        super(vec3(x, y, 0), unitbox[layer.shader], new Material(null, null));

        //---------------------------------------------------------------------

        //tex = font.texture(text);

        foreach(i, s; std.string.split(text, "%"))
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

        layer.add(this);
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

    void   opIndexAssign(string value, string name) { fields[name].value = value; }
    Dynamic opIndex(string name) { return fields[name]; }

    //-------------------------------------------------------------------------

    void prepare(string chars)
    {
        foreach(c; chars) font.render(c);
    }

    //-------------------------------------------------------------------------
    // TODO: Does not work

    void render(Shader shader)
    {
        import engine.render.util;

        auto cursor = new Bone(grip);
        int max_height = 0;
        
        foreach(elem; elems) {
            //shape.material.color = elem.color;
            foreach(c; elem.content) {
                if(c == '\n') {
                    cursor.pos.x = 0;
                    cursor.pos.y += max_height;
                    max_height = 0;
                }
                else {
                    model.material.colormap = font.render(c);

                    cursor.scale = vec3(
                        model.material.colormap.width,
                        model.material.colormap.height,
                        0
                    );

                    shader.render(cursor, model.material, model.vao);
                    cursor.pos.x += model.material.colormap.width;
                    max_height = max(max_height, model.material.colormap.height);
                }
            }
        }
    }

    //-------------------------------------------------------------------------

    private static Shader.VAO[Shader] unitbox;

    //-----------------------------------------------------------------------------
    //-----------------------------------------------------------------------------
}
}

//*****************************************************************************
//*****************************************************************************

class Font
{
    //-------------------------------------------------------------------------

    static Font[string] fonts;

    static Font load(string filename, int size)
    {
        string fontname = filename ~ ":" ~ to!string(size);

        if(!(fontname in fonts))
        {
            fonts[fontname] = new Font(blob.loadfont(filename, size), fontname);
        }
        return fonts[fontname];
    }

    //-------------------------------------------------------------------------

    import derelict.sdl2.ttf;

    private
    {
        string ID;
        TTF_Font *font;
        Texture[char] rendered;

        this(TTF_Font *font, string ID)
        {
            this.font = font;
            this.ID = ID;
        }

        ~this()
        {
            TODO("Segfaults");
            //TTF_CloseFont(font); font = null;
        }
    }

    //-------------------------------------------------------------------------

    Font setstyle(int style)
    {
        TTF_SetFontStyle(font, style);
        return this;
    }

    Font setoutline(int width)
    {
        TTF_SetFontOutline(font, width);
        return this;
    }

    //-------------------------------------------------------------------------

    Texture render(char c) {
        if(!(c in rendered)) {
            rendered[c] = texture(to!string(c));
        }
        return rendered[c];
    }

    Texture texture(string text) {
        SDL_Color color={255, 255, 255, 255};

        auto bitmap = TTF_RenderText_Blended(font, std.string.toStringz(text), color);
        if(!bitmap) throw new TTFError(
            format(
                "TTF_RenderText_Blended: %s ('%s')",
                to!string(TTF_GetError()),
                text
            )
        );
        auto texture = new Texture(bitmap);
        SDL_FreeSurface(bitmap);
        return texture;
    }

    //-------------------------------------------------------------------------
}

