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

    override void draw(Canvas canvas, mat4 local)
    {
        mat4 m = Transform.matrix(pos.x, pos.y);
        child.draw(canvas, local * m);
    }
}

//-----------------------------------------------------------------------------

class Anchor : Wrapping
{
    import engine.game.instance;

    vec2 anchor;

    this(vec2 anchor, Widget child)
    {
        super(child);
        this.anchor = anchor;
    }

    this(float ax, float ay, Widget child)
    {
        this(vec2(ax, ay), child);
    }
    
    override void draw(Canvas canvas, mat4 local)
    {
        float x, y;

        vec2 dim = (parent) ? vec2(parent.width, parent.height) : vec2(screen.width, screen.height);

        x = anchor.x * (dim.x - child.width);
        y = anchor.y * (dim.y - child.height);

        mat4 m = Transform.matrix(x, y);
        child.draw(canvas, local * m);
    }
}

//-----------------------------------------------------------------------------

class Padding : Wrapping
{
    vec2 topleft;
    vec2 bottomright;

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
    
    override float width() { return child.width + topleft.x + bottomright.x; }
    override float height() { return child.height + topleft.y + bottomright.y; }
    
    override void draw(Canvas canvas, mat4 local)
    {
        mat4 m = Transform.matrix(topleft.x, topleft.y);
        child.draw(canvas, local * m);
    }
}

