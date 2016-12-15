//*****************************************************************************
//
// Simple object viewer
//
//*****************************************************************************

import engine;

//-----------------------------------------------------------------------------

import std.random;
import std.stdio;

//-----------------------------------------------------------------------------

void main()
{
    engine.asset.scenegraph.load("engine/stock/unsorted/mesh/Chess/bishop.obj");
}

static if(0) void main()
{
    //-------------------------------------------------------------------------
    // Init game with default window size
    //-------------------------------------------------------------------------

    game.init();

    auto pipeline = new scene3d.SimplePipeline();

    with(pipeline)
    {
        cam = scene3d.Camera.basic3D(
            0.1, 10,        // Near - far
            scene3d.Grip.movable(0, 0, 5)
        );

        light = new scene3d.Light(
            scene3d.Grip.fixed(2, 2, 0),    // Position
            vec3(1, 1, 1),                  // Color
            7.5,                            // Range
            0.25                            // Ambient level
        );
    }

    auto node = pipeline.add(
        scene3d.Grip.movable, 
            //blob.wavefront.loadmesh("engine/stock/mesh/Cube/CubeWrap.obj")
            //blob.wavefront.loadmesh("engine/stock/mesh/Suzanne/Suzanne.obj"),
            //blob.wavefront.loadmesh("engine/stock/mesh/Chess/bishop.obj"),
            //blob.wavefront.loadmesh("engine/stock/mesh/Chess/king.obj"),
            //blob.wavefront.loadmesh("engine/stock/mesh/Chess/knight.obj"),
            //blob.wavefront.loadmesh("engine/stock/mesh/Chess/pawn.obj"),
            //blob.wavefront.loadmesh("engine/stock/mesh/Chess/queen.obj"),
            blob.wavefront.loadmesh("engine/stock/unsorted/mesh/Chess/rook.obj"),
        pipeline.material(
            //"engine/stock/tiles/Concrete/Dirty/ColorMap.png",
            vec4(1, 0.8, 0, 1)
            //"engine/stock/tiles/Concrete/Dirty/NormalMap.png",
            //0.75
        )
    );

    //-------------------------------------------------------------------------
    // Control
    //-------------------------------------------------------------------------

    pipeline.actors.addcallback(() {
        const float moverate = 0.25;
        const float turnrate = 5;

        node.grip.pos += vec3(
            game.controller.axes[game.JOY.AXIS.LX],
            0,
            -game.controller.axes[game.JOY.AXIS.LY]
        ) * moverate;

        node.grip.rot += vec3(
            game.controller.axes[game.JOY.AXIS.RY],
            game.controller.axes[game.JOY.AXIS.RX],
            0
        ) * turnrate;
    });

    //-------------------------------------------------------------------------

    pipeline.actors.reportperf();

    //-------------------------------------------------------------------------

    bool processevents(SDL_Event event)
    {
        switch(event.type)
        {
            default: break;
            case SDL_KEYDOWN: switch(event.key.keysym.sym)
            {
                default: break;
                //case SDLK_w: scene.shader.fill = !scene.shader.fill; break;
                //case SDLK_e: scene.shader.enabled = !scene.shader.enabled; break;
                /*
                case SDLK_r: {
                    static bool normmaps = true;
                    normmaps = !normmaps;
                    maze.shader.activate();
                    maze.shader.uniform("useNormalMapping", normmaps);
                } break;
                */
            }
        }
        return true;
    }

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,             // FPS (limit)
        &pipeline.draw,    // Drawing
        pipeline.actors,   // list of actors
        &processevents
    );
}

