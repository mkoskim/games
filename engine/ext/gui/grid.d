//*****************************************************************************
//
// Widget grids
//
//*****************************************************************************

module engine.ext.gui.grid;

import engine.ext.gui.util;

//-----------------------------------------------------------------------------

private abstract class GridContainer : Widget
{
    //-------------------------------------------------------------------------
    
    struct COLUMN { float x; float width; }
    
    struct ROW { float y; float height; }

    COLUMN[] cols;
    ROW[] rows;

    //-------------------------------------------------------------------------
    
    struct KEY { int row, col; }
    
    class Cell : Widget
    {
        GridContainer parent;
        KEY key;
        Widget child;

        this(GridContainer parent, int col, int row, Widget child) {
            this.parent = parent;
            this.key = KEY(row, col);
            this.child = child;

            parent.cols[col].width = max(parent.cols[col].width, child.width);
            parent.rows[row].height = max(parent.rows[row].height, child.height);
        }

        vec2 pos() { return vec2(parent.cols[key.col].x, parent.rows[key.row].y); }
        
        override float width() { return parent.cols[key.col].width; }
        override float height() { return parent.rows[key.row].height; }

        override void draw(Canvas canvas, vec2 offset, vec2 size)
        {
            child.draw(canvas, offset + pos, vec2(width, height));
        }
    }

    Cell[KEY] cells;

    //-------------------------------------------------------------------------
    
    void add(int col, int row, Widget shape)
    {
        if(cols.length <= col) cols ~= COLUMN(0, 0);
        if(rows.length <= row) rows ~= ROW(0, 0);
        auto cell = new Cell(this, col, row, shape);
        cells[cell.key] = cell;
    }

    protected void calcdim()
    {
        cols[0].x = 0;
        foreach(i; 1 .. cols.length) cols[i].x = cols[i-1].x + cols[i-1].width;
        rows[0].y = 0;
        foreach(i; 1 .. rows.length) rows[i].y = rows[i-1].y + rows[i-1].height;
    }

    override float width() {
        size_t last = cols.length - 1;
        return cols[last].x + cols[last].width;
    }

    override float height() {
        size_t last = rows.length - 1;
        return rows[last].y + rows[last].height;
    }
    
    override void draw(Canvas canvas, vec2 offset, vec2 size)
    {
        foreach(key, cell; cells) cell.draw(canvas, offset, size);
    }
}

//-----------------------------------------------------------------------------

class Grid : GridContainer
{
    this(Widget[] shapes) {
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

    this(Widget[] shapes...) { this(shapes); }    
}

//-----------------------------------------------------------------------------
// This is in fact a decoration...
//-----------------------------------------------------------------------------

static if(0) class Frame : Widget
{
    Box[][] boxes;
    Widget child;
    
    this(Texture[][] textures, Widget child)
    {
        import engine.ext.gui.box;

        super();
    
        this.child = child;

        boxes = Box.create(textures);

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

