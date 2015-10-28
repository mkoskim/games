//*****************************************************************************
//
// Wolfenstein-style FPS project for game engine experimenting.
//
// Wolfenstein style FPS is "pseudo-3D", as all action still happens in
// two dimensions as in pacman. This project is mainly used for:
//
// - Experiment materials and lighting
// - Experiment general architecture of creating 3D worlds
// - Later: experiment moving in 3D navmeshes
//
//*****************************************************************************

import engine;

static import std.random;

//*****************************************************************************
//
// Grid
//
//*****************************************************************************

string[] grid = [
//   12345678901234567890
    "222222222########",
    "2       2       #",
    "2 nnn   2  XXX  #",
    "2 n n   2  XXX  #",
    "2 nnn   2  XXX  #",
    "2       2       # 5555555",
    "2       2#  #444445     5",
    "2       2               5",
    "22222 222    4    5     5",
    "#####        444445555555",
    "#   #        3    3",
    "#      X X X      3",
    "#   #        3    3",
    "# # #    @   333333",
    "#                 #",
    "#      #####      #",
    "#                 #",
    "#        #        #",
    "###################",
];


//*****************************************************************************
//
// Maze from grid (TODO: Move this to loader.d, when resolving how to
// (easily) transfer player position here.
//
//*****************************************************************************

void loadmaze(scene3d.Pipeline pipeline, string[] grid)
{
    import loader: loadasset;
    
    loadasset(pipeline);
    
    auto nodes = pipeline.nodes.add("maze");
    auto asset = pipeline.assets("maze");

    //---------------------------------------------------------------------
    // Create nodes from grid
    //---------------------------------------------------------------------
    
    foreach(y, line; grid)
    {
        foreach(x, c; line)
        {
            vec3 pos = vec3(2*x, 0, 2*(cast(int)y - cast(int)grid.length));
            
            switch(c)
            {
                default:
                    enforce(
                        to!string(c) in asset.models,
                        format("Invalid character: '%c'", c)
                    );
                    nodes.add(pos, asset[to!string(c)]);
                    break;

                /* Add floor under prop */
                case 'X':
                    nodes.add(pos, asset("X"));
                    nodes.add(pos, asset(" "));
                    break;

                /* Add floor under player */
                case '@':
                    nodes.add(pos, asset(" "));
                    new Player(pipeline, pos);
                    break;
            }
        }
    }

    //---------------------------------------------------------------------
    // If we don't have to create objects anymore, we can throw loaded
    // models away.
    //---------------------------------------------------------------------

    pipeline.assets.remove("maze");
    game.rungc();
}

//*****************************************************************************
//
// Player (camera)
//
//*****************************************************************************

class Player : game.Fiber
{
    scene3d.Transform root;
    scene3d.Camera cam;
    float zoom;

    this(scene3d.Pipeline pipeline, vec3 pos)
    {
        super(pipeline.actors);

        root = scene3d.Grip.movable(pos);
        cam = scene3d.Camera.basic3D(
            0.1, 20,
            scene3d.Grip.movable(root)
        );

        pipeline.light = new scene3d.Light(
            scene3d.Grip.fixed(0, 2, 0),
            vec3(1, 1, 1),
            10,
            0.2
        );
        pipeline.cam = cam;
    }

    override void run()
    {
        const float turnrate = 5;
        const float maxspeed = 0.1;

        const auto zoom = new Translate(vec2(-1, 60), vec2(1, 30));

        for(;;nextframe())
        {
            vec3 forward = (root.mModel() * vec4( 0, 0, +1, 0)).xyz;
            vec3 strafe  = (root.mModel() * vec4(+1, 0,  0, 0)).xyz;

            root.grip.pos +=
                forward * game.controller.axes[game.JOY.AXIS.LY] * maxspeed +
                strafe  * game.controller.axes[game.JOY.AXIS.LX] * maxspeed;

            root.grip.rot.y -= game.controller.axes[game.JOY.AXIS.RX] * turnrate;
            cam.grip.rot.x = clamp(
                cam.grip.rot.x - game.controller.axes[game.JOY.AXIS.RY] * turnrate,
                -30, 30
            );
            
            // TODO: Zooming - we want to use 'sniper riffle' to drop down
            // an enemy.
            
            cam.setProjection(
                zoom(game.controller.axes[game.JOY.AXIS.LT]),
                0.1, 20
            );
        }
    }
}

//-----------------------------------------------------------------------------

import loader: createPipeline;

void main()
{
    game.init(800, 600);

    auto pipeline = createPipeline();

    loadmaze(pipeline, grid);

    //-------------------------------------------------------------------------

    void draw()
    {
        pipeline.draw();
        //maze.skybox.draw(maze.cam.mView(), maze.cam.mProjection());
        //hud.draw();
    }

    //-------------------------------------------------------------------------

    bool processevents(SDL_Event event)
    {
        switch(event.type)
        {
            default: break;
            case SDL_KEYDOWN: switch(event.key.keysym.sym)
            {
                default: break;
                //case SDLK_w: maze.shader.fill = !maze.shader.fill; break;
                //case SDLK_e: maze.shader.enabled = !maze.shader.enabled; break;
            }
        }
        return true;
    }

    //-------------------------------------------------------------------------

    pipeline.actors.reportperf;

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,              // FPS
        &draw,           // draw
        pipeline.actors, // list of actors
        &processevents
    );
}

//*****************************************************************************
//*****************************************************************************
//*****************************************************************************
//*****************************************************************************

    //-------------------------------------------------------------------------

    //auto hud = new Canvas();

    /*
    auto txtInfo = new TextBox(2, 2,
        "%info%\n"
        "CAM....: (%cam.x%, %cam.z%)\n"
        "Objects: %drawn% / %total%\n"
        "GL.....: %calls%\n"
        "\n"
        "Mat....: r = %mat.r%\n"
    );

    hud.add(txtInfo);

    maze.actors.addcallback(() {
        txtInfo["info"] = game.Profile.info();
        txtInfo["cam.x"] = format("%.1f", maze.player.root.grip.pos.x);
        txtInfo["cam.z"] = format("%.1f", maze.player.root.grip.pos.z);
        //txtInfo["drawn"] = format("%d", maze.perf.drawed);
        //txtInfo["total"] = format("%d", maze.nodes.length);
        //txtInfo["mat.r"] = format("%.2f", maze.mat.roughness);

        import engine.render.util: glcalls;
        txtInfo["calls"] = format("%d", glcalls);
        glcalls = 0;
    });
    */

    //writeln("VBO row size: ", render.Mesh.VERTEX.sizeof);
    //writeln(to!string(glGetString(GL_EXTENSIONS)));

