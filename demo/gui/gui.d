//*****************************************************************************
//
// GUI sketching
//
//*****************************************************************************

import engine;

import std.stdio;

//-----------------------------------------------------------------------------
//
// What would we like to have...
//
// - Layouts: no need to set coordinates nor dimensions
// - Simple keyboard/controller traversal
//
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------

void main()
{
    game.init();
    
    auto actors = new game.FiberQueue();

    //-------------------------------------------------------------------------

    auto canvas = new Canvas();

    auto box = new HBox(
        new Box(20, 20, vec4(1, 1, 0, 1)),
        new Box(10, 10, vec4(0, 1, 1, 1)),
        new Box(30, 10, vec4(0, 1, 0, 1)),
        new Box(10, 30, vec4(1, 0, 1, 1))
    );
    
    canvas.add(new Position(50, 50, box));

    //-------------------------------------------------------------------------

    simple.gameloop(
        &canvas.draw,
        actors
    );
}

