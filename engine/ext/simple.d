//*****************************************************************************
//
// Some simplers to speed up certain things
//
//*****************************************************************************

module engine.ext.simple;

//-----------------------------------------------------------------------------

import game = engine.game;
import render = engine.render;
import engine.util;

//*****************************************************************************
//
// Game loop: The conventional way is:
//
//      1) get events
//      2) update game world
//      3) render game world
//      4) wait next frame / user reactions
//
// Here, we reorganize it as following:
//
//      1) render game world
//      2) wait next frame / user reactions
//      3) get events
//      4) update game world
//
// With this reorganization, information can be sent from render phase to
// game update, for example, screen coordinates of objects or object under
// "hotspot" (crosshair, mouse). Without reorganizing, at first pass the
// information is not available for updating phase.
//
//*****************************************************************************

void gameloop(
    void delegate() draw,
    game.FiberQueue actors,
    bool delegate(SDL_Event *) process = null
)
{
    loop: for(;;)
    {
        game.startdraw();
        if(draw) draw();
        game.waitframe();

        foreach(event; game.getevents())
        {
            if(process) if(!process(event)) break loop;
        }

        if(actors) actors.update();
    }
}

//-----------------------------------------------------------------------------

void gameloop(
    int FPS,
    void delegate() draw,
    game.FiberQueue actors,
    bool delegate(SDL_Event *) process = null
)
{
    game.fps = FPS;
    gameloop(draw, actors, process);
}

