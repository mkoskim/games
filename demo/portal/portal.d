//*****************************************************************************
//
// Portal demonstration.
//
//*****************************************************************************

import engine;

//-----------------------------------------------------------------------------

class Room
{
    InstanceGroup content;

    this() { }
    ~this() { }
}

//-----------------------------------------------------------------------------

void main()
{
    //-------------------------------------------------------------------------
    
    game.init();

    //-------------------------------------------------------------------------
    // Scene! Lights! Camera!
    //-------------------------------------------------------------------------
        
    auto scene = new render.Scene();

    scene.light = new render.Light(
        vec3(0, 2, 0),      // Position
        vec3(1, 1, 1),      // Color
        10,                 // Range
        0.1                 // Ambient level
    );

    auto cam = render.Camera.basic3D(
        0.1, 20,        // Near - far
        vec3(0, 0, 5)
    );

    //-------------------------------------------------------------------------
    // Actor to stage
    //-------------------------------------------------------------------------
    
    auto shape = new render.Shape(
        scene.shader.upload(
            //blob.wavefront.loadmesh("engine/stock/mesh/Cube/CubeWrap.obj")
            blob.wavefront.loadmesh("engine/stock/mesh/Suzanne/Suzanne.obj")
        ),
        new render.Material(
            new render.Texture("engine/stock/tiles/Concrete/Crusty/ColorMap.png"),
            new render.Texture("engine/stock/tiles/Concrete/Crusty/NormalMap.png"),
            0.95
        )
    );

    auto object = scene.add(vec3(0, 0, 0), shape);

    //-------------------------------------------------------------------------
    // Control
    //-------------------------------------------------------------------------

    auto actors = new game.FiberQueue();
    auto joystick = game.joysticks[0];

    actors.addcallback(() {
        const float moverate = 0.25;
        const float turnrate = 5;
        
        object.grip.pos += vec3(
            -joystick.axes[game.JOY.AXIS.LX],
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

    simple.gameloop(
        50,                         // FPS (limit)
        (){ scene.draw(cam); },     // Drawing
        actors,                     // list of actors

        //---------------------------------------------------------------------

        (SDL_Event* event) {
            switch(event.type)
            {
                default: break;
                case SDL_KEYDOWN: switch(event.key.keysym.sym)
                {
                    default: break;
                    case SDLK_w: scene.shader.fill = !scene.shader.fill; break;
                    case SDLK_e: scene.shader.enabled = !scene.shader.enabled; break;
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

