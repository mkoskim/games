//-----------------------------------------------------------------------------
// Positioning
//-----------------------------------------------------------------------------

module engine.ext.gui.placement;

//-----------------------------------------------------------------------------

import engine.ext.gui.util;

//-----------------------------------------------------------------------------

class Position : Wrapping
{
    vec2 pos;

    this(float x, float y, Widget child)
    {
        super(child);
        this.pos = vec2(x, y);
    }

    override void draw(Canvas canvas, vec2 offset, vec2 size)
    {
        child.draw(canvas, offset + pos, vec2(0, 0));
    }
}

//-----------------------------------------------------------------------------

class Anchor : Wrapping
{
    vec2 anchor;

    //-------------------------------------------------------------------------

    this(vec2 anchor, Widget child)
    {
        super(child);
        this.anchor = anchor;
    }

    this(float ax, float ay, Widget child)
    {
        this(vec2(ax, ay), child);
    }
    
    //-------------------------------------------------------------------------

    static Widget[] wrap(float ax, float ay, Widget[] widgets...)
    {
        Anchor[] wrapped;
        foreach(widget; widgets) {
            wrapped ~= widget ? new Anchor(ax, ay, widget) : null;
        }
        return cast(Widget[])wrapped;
    }

    //-------------------------------------------------------------------------

    override void draw(Canvas canvas, vec2 offset, vec2 area)
    {
        child.draw(canvas, anchorpoint(offset, area, anchor), child.size);
    }
}

//-----------------------------------------------------------------------------

class Padding : Wrapping
{
    vec2 topleft;
    vec2 bottomright;

    //-------------------------------------------------------------------------

    this(vec2 topleft, vec2 bottomright, Widget child)
    {
        super(child);
        this.topleft = topleft;
        this.bottomright = bottomright;
    }

    this(vec2 pad, Widget child)
    {
        this(pad, pad, child);
    }
    
    this(float px, float py, Widget child)
    {
        this(vec2(px, py), child);
    }
    
    //-------------------------------------------------------------------------

    static Widget[] wrap(float px, float py, Widget[] widgets...)
    {
        Padding[] wrapped;
        foreach(widget; widgets) {
            wrapped ~= widget ? new Padding(px, py, widget) : null;
        }
        return cast(Widget[])wrapped;
    }

    //-------------------------------------------------------------------------

    override float width() { return child.width + topleft.x + bottomright.x; }
    override float height() { return child.height + topleft.y + bottomright.y; }
    
    override void draw(Canvas canvas, vec2 offset, vec2 size)
    {
        child.draw(canvas, offset + topleft, size - topleft - bottomright);
    }
}

