//*****************************************************************************
//
// Labels
//
//*****************************************************************************

module engine.ext.gui.label;

import engine.ext.gui.util;
import engine.ext.gui.widget;

import engine.ext.font;

//-----------------------------------------------------------------------------

class Label : Widget
{
    string text;
    string delegate() update;

    //-------------------------------------------------------------------------
    
    static class Style
    {
        vec4 color;
        Font font;
        vec2 anchor;
        
        //---------------------------------------------------------------------

        this(Font font, vec4 color)
        {
            if(!font) {
                //font = Font.load("engine/stock/fonts/default.ttf", 12);
                //font = Font.load("engine/stock/fonts/dejavu/ttf/DejaVuSansMono.ttf", 12);
                font = Font.load("engine/stock/fonts/dejavu/ttf/DejaVuSans.ttf", 12);
                //font = Font.load("engine/stock/fonts/dejavu/ttf/DejaVuSerif.ttf", 12);
            }

            this.font = font;
            this.color = color;
            this.anchor = vec2(0, 0);
        }
        
        Style setanchor(float x, float y) {
            this.anchor = vec2(x, y);
            return this;
        }

        //---------------------------------------------------------------------

        Label opCall(string text) { return (new Label(text)).setstyle(this); }
        Label opCall(string delegate() update) { return (new Label(update)).setstyle(this); }

        //---------------------------------------------------------------------

        static Style[string] styles;

        static Style add(string name, Font font, vec4 color) {
            auto style = new Style(font, color);
            styles[name] = style;
            return style;
        }

        static Style opIndex(string name) { return styles[name]; }

    }

    static Style opIndex(string stylename) { return Style[stylename]; }

    //-------------------------------------------------------------------------
    
    private Style style;

    Label setstyle(Style style) { this.style = style; return this; }

    //-------------------------------------------------------------------------

    protected this(string text)
    {
        this.text = text;
    }

    protected this(string delegate() update)
    {
        this.update = update;
    }

    //-------------------------------------------------------------------------
    
    override float width()
    {
        float w = 0;
        foreach(c; text) w = w + style.font.render(c).width;
        return w;
    }
    
    override float height()
    {
        float h = 0;
        foreach(c; text) h = max(h, style.font.render(c).height);
        return h;
    }

    override void draw(Canvas canvas, vec2 offset, vec2 area)
    {
        if(update) text = update();
        
        vec2 cursor = anchorpoint(offset, area, style.anchor);
        
        foreach(c; text) {
            Texture tex = style.font.render(c);

            canvas.render(cursor, tex.size(), tex, style.color);
            cursor.x += tex.width;
        }
    }
}

