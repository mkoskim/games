//*****************************************************************************
//
// Warriors is a fighting game in a fantasy world.
//
//*****************************************************************************

import engine;

import std.stdio;
import std.string;
import std.array;

//*****************************************************************************
//
// Road map planning:
//
// - Navmesh for player & mob movement
// - Testing AI at some simplified arena
// - Sketching UI
//
//*****************************************************************************

//-----------------------------------------------------------------------------
//
// Main focus ATM: Design the UI for fighting.
//
//-----------------------------------------------------------------------------

//*****************************************************************************
//*****************************************************************************

void main()
{
    game.init();
    
    //auto layer  = simple.init2D();

    auto actors = new game.FiberQueue();

    auto sheet = render.Texture.upload(
        Bitmap.splitSheet(
            "data/spritesheets/KBQkz/1 - 4cpmn.png",
            vec2i(46, 46),
            vec2i(46, 46),
            vec2i(2, 2),
            vec2i(2, 2)
        )
    );

    auto canvas = new gui.Canvas();
    
    auto grid = new gui.Grid();

    foreach(y, row; sheet) foreach(x, tex; row) {
        grid.add(x, y, new gui.Padding(2, 2, new gui.Box(tex, 32, 32)));
    }

    canvas.add(new gui.Anchor(0.5, 0.5, grid));

    //-------------------------------------------------------------------------

    game.Track.report();
    game.Track.rungc();
    game.Track.report();

    //-------------------------------------------------------------------------

    simple.gameloop(
        &canvas.draw,
        actors
    );

    static if(0) {
        foreach(event; game.getevents()) switch(event.type)
        {
            case SDL_JOYBUTTONDOWN:
            case SDL_JOYBUTTONUP:
                player.addevent(event);
                break;

            default: break;
        }

        //---------------------------------------------------------------------

        actors.update();
    }
}

