//*****************************************************************************
//
// Widgets
//
//*****************************************************************************

module engine.ext.gui.widget;

import engine.ext.gui.util;

//-----------------------------------------------------------------------------

abstract class Widget
{
    this() {
    }

    //-------------------------------------------------------------------------

    abstract float width();
    abstract float height();

    vec2 size() { return vec2(width, height); }

    //-------------------------------------------------------------------------

    vec2 anchorpoint(vec2 offset, vec2 area, vec2 anchor) {
        return vec2(
            offset.x + anchor.x * (area.x - width),
            offset.y + anchor.y * (area.y - height)
        );
    }

    //-------------------------------------------------------------------------

    abstract void draw(Canvas canvas, vec2 offset, vec2 size);
}

//-----------------------------------------------------------------------------

abstract class Wrapping : Widget
{
    Widget child;

    this(Widget child)
    {
        this.child = child;
    }

    override float width() { return child.width(); }
    override float height() { return child.height(); }    
}

