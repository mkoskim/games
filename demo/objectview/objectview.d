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
    //-------------------------------------------------------------------------

    game.init();

    //-------------------------------------------------------------------------
    // Scene! Lights! Camera!
    //-------------------------------------------------------------------------

    auto cam = scene3d.Camera.basic3D(
        0.1, 10,        // Near - far
        scene3d.Grip.movable(0, 0, 5)
    );

    auto scene = new scene3d.UnbufferedRender(
        cam,
        scene3d.State.Solid3D()
    );

    scene.light = new scene3d.Light(
        scene3d.Grip.fixed(2, 2, 0),    // Position
        vec3(1, 1, 1),                  // Color
        7.5,                            // Range
        0.25                            // Ambient level
    );

    auto nodes = scene.addbatch();

    //-------------------------------------------------------------------------
    // Actor to stage
    //-------------------------------------------------------------------------
    
    auto model = nodes.upload(
        //blob.wavefront.loadmesh("engine/stock/mesh/Cube/CubeWrap.obj")
        //blob.wavefront.loadmesh("engine/stock/mesh/Suzanne/Suzanne.obj"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Chess/bishop.obj"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Chess/king.obj"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Chess/knight.obj"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Chess/pawn.obj"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Chess/queen.obj"),
        blob.wavefront.loadmesh("engine/stock/mesh/Chess/rook.obj"),
        new scene3d.Material(
            //new render.Texture("engine/stock/tiles/Concrete/Dirty/ColorMap.png"),
            render.Texture.Loader.Default(vec4(1, 0.8, 0, 1)),
            //new render.Texture("engine/stock/tiles/Concrete/Dirty/NormalMap.png"),
            //0.75
        )
    );

    auto object = scene.add(scene3d.Grip.movable, model);

    //object.grip.pos -= model.vao.bsp.center;

    //-------------------------------------------------------------------------
    // Control
    //-------------------------------------------------------------------------

    auto actors = new game.FiberQueue();
    auto joystick = game.joysticks[0];

    actors.addcallback(() {
        const float moverate = 0.25;
        const float turnrate = 5;

        object.grip.pos += vec3(
            joystick.axes[game.JOY.AXIS.LX],
            0,
            -joystick.axes[game.JOY.AXIS.LY]
        ) * moverate;

        object.grip.rot += vec3(
            joystick.axes[game.JOY.AXIS.RY],
            joystick.axes[game.JOY.AXIS.RX],
            0
        ) * turnrate;
    });

    //-------------------------------------------------------------------------

    actors.reportperf();

    //-------------------------------------------------------------------------

    void draw() {
        scene.draw();
    }

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,       // FPS (limit)
        &draw,    // Drawing
        actors,   // list of actors

        //---------------------------------------------------------------------

        (SDL_Event event) {
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
    );
}

