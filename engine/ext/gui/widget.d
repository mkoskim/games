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
    Widget parent;

    //-------------------------------------------------------------------------

    this(Widget parent) {
        this.parent = parent;
    }

    this() {
    }

    //-------------------------------------------------------------------------

    abstract float width();
    abstract float height();

    //-------------------------------------------------------------------------

    abstract void draw(Canvas canvas, mat4 local);
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

