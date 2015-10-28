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
import std.stdio: writeln;

//*****************************************************************************
//
// Pipeline construction: This demonstrates how to create multiple batches
// with different shaders and rendering order. We create following
// batches:
//
//      name            shader      order
//
//      walls           default     solid (front2back)
//      props           default     solid
//      floors          default     solid
//      transparent     default     transparent (back2front)
//
//*****************************************************************************

scene3d.Pipeline createPipeline()
{
    auto pipeline = new scene3d.Pipeline();

    //-------------------------------------------------------------------------
    // Create and configure shaders and (rendering) states for later use. We
    // usually need at least solid and transparent batches.
    //-------------------------------------------------------------------------

    auto shaders = pipeline.shaders;
    
    shaders.Default3D("default");
    //shaders.Flat3D("flat");
    
    {   auto shader = shaders["default"];
        shader.options["fog.enabled"] = true;
        shader.options["fog.start"] = 15.0;
        shader.options["fog.end"]   = 20.0;
        shader.options["fog.color"] = vec4(0.0, 0.0, 0.0, 1);
    }

    auto states = pipeline.states;

    states.Solid3D("solid", shaders["default"]);
    states.Transparent3D("transparent", shaders["default"]);

    //-------------------------------------------------------------------------
    // Create batches for objects. In general, the simpler and faster it is
    // to render an object and the more it can occlude other things, the earlier
    // we want render it - this way, Z buffering prevents us to do wasted work.
    //
    // We give names to batches, so that our level loaders can place objects
    // to correct rendering phase.
    //
    //-------------------------------------------------------------------------

    auto batches = pipeline.batches;

    batches.add("walls",  states["solid"]);
    batches.add("props",  states["solid"]);
    batches.add("floors", states["solid"]);
    batches.add("transparent", states["transparent"], scene3d.Batch.Mode.back2front);

    return pipeline;
}

//*****************************************************************************
//
// Maze: This demonstrates/experiments how games can load levels. Key points:
//
// 1) Ready-made pipeline: This can already contain items that are shared
//    between levels (e.g. player objects).
//
// 2) Level asset management: When changing level, we need to get rid of
//    objects needed by previous level.
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

void loadmaze(scene3d.Pipeline pipeline, string[] grid)
{
    //---------------------------------------------------------------------
    // Clear previous level
    //---------------------------------------------------------------------

    auto nodes = pipeline.nodes.add("maze");
    auto asset = pipeline.assets.add("maze");

    string path(string filename) { return "engine/stock/unsorted/" ~ filename; }

    //---------------------------------------------------------------------
    // Load meshes
    //---------------------------------------------------------------------

    asset.upload("wall",   blob.wavefront.loadmesh(path("mesh/Cube/CubeWrap.obj")));
    asset.upload("floor",  blob.wavefront.loadmesh(path("mesh/Cube/Floor.obj")));
    asset.upload("monkey", blob.wavefront.loadmesh(path("mesh/Suzanne/Suzanne.obj")).scale(0.66));
    
    //---------------------------------------------------------------------
    // Load materials
    //---------------------------------------------------------------------

    auto material = pipeline.assets.material;     // Material loader

    asset.upload("CaveWall", material(
        path("tiles/CaveWall/ColorMap.png"),
        path("tiles/CaveWall/NormalMap.png"),
        1.00));

    asset.upload("CrackedPlaster", material(
        path("tiles/CrackedPlaster/ColorMap.png"),
        path("tiles/CrackedPlaster/NormalMap.png"),
        0.95));

    asset.upload("SantaFeStucco", material(
        //"engine/stock/tiles/SantaFeStucco/ColorMap.png",
        path("tiles/CaveWall/ColorMap.png"),
        path("tiles/SantaFeStucco/NormalMap.png"),
        0.95));

    asset.upload("TanStucco", material(
        //"engine/stock/tiles/SantaFeStucco/ColorMap.png",
        path("tiles/TanStucco/ColorMap.png"),
        path("tiles/TanStucco/NormalMap.png"),
        0.95));

    asset.upload("BrickWall", material(
        path("tiles/BrickWall1/ColorMap.png"),
        path("tiles/BrickWall1/NormalMap.png"),
        0.95));

    asset.upload("GraniteWall", material(
        path("tiles/GraniteWall/ColorMap.png"),
        path("tiles/GraniteWall/NormalMap.png"),
        0.95));

    asset.upload("CrustyConcrete", material(
        path("tiles/Concrete/Crusty/ColorMap.png"),
        path("tiles/Concrete/Crusty/NormalMap.png"),
        0.95));

    asset.upload("DirtyConcrete", material(
        path("tiles/Concrete/Dirty/ColorMap.png"),
        path("tiles/Concrete/Dirty/NormalMap.png"),
        0.95));

    asset.upload("CarvedSandstone", material(
        path("tiles/CarvedSandstone/ColorMap.png"),
        //"engine/stock/tiles/CaveWall/ColorMap.png",
        //vec3(0.5, 0.4, 0.2),
        path("tiles/CarvedSandstone/NormalMap.png"),
        0.95));

    asset.upload("AlienCarving", material(
        //"engine/stock/tiles/AlienCarving/ColorMap.png",
        vec4(0.75, 0.5, 0.25, 1),
        path("tiles/AlienCarving/NormalMap.png"),
        0.15));

    asset.upload("MetallicAssembly", material(
        //"engine/stock/tiles/MetallicAssembly/ColorMap.png",
        vec4(0.5, 0.5, 0.5, 1),
        path("tiles/MetallicAssembly/NormalMap.png"),
        0.15));

    asset.upload("Glass", material(
        vec4(0.8, 0.8, 0.9, 0.3),
        "engine/stock/unsorted/tiles/SantaFeStucco/NormalMap.png",
        0.50));

    //---------------------------------------------------------------------

    auto floormat = asset.upload("Floor", asset.materials["GraniteWall"]);
    asset.upload("PaintedFloor", material(
        vec4(0.25, 0.25, 0.25, 1),
        floormat.normalmap,
        floormat.roughness));
        
    //---------------------------------------------------------------------
    // Make shortcuts to pipeline batches
    //---------------------------------------------------------------------

    auto batches = pipeline.batches;
    
    auto walls  = batches["walls"];
    auto floors = batches["floors"];
    auto props  = batches["props"];
    auto transparent = batches["transparent"];
    
    //---------------------------------------------------------------------
    // Create model lookup table
    //---------------------------------------------------------------------
    
    asset.upload("1", walls, "wall", "CaveWall");
    asset.upload("2", walls, "wall", "BrickWall");
    asset.upload("3", walls, "wall", "DirtyConcrete");
    asset.upload("4", walls, "wall", "MetallicAssembly");
    asset.upload("5", walls, "wall", "AlienCarving");
    asset.upload("#", asset("1"));

    asset.upload(" ", floors, "floor", "Floor");
    asset.upload("n", floors, "floor", "PaintedFloor");

    asset.upload("X", transparent, "monkey", "Glass");

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
}

//*****************************************************************************
//
// Sketching render pipelining:
//
// 1) We need shaders, or at least their interfaces.
// 2) Then we load assets
// 3) And place them to node groups
//
//*****************************************************************************

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

class Player : game.Fiber
{
    scene3d.Transform root;
    scene3d.Camera cam;

    this(scene3d.Pipeline pipeline, vec3 pos)
    {
        super(pipeline.actors);
        //super();

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
        //pipeline.actors.add(this);
    }

    override void run()
    {
        const float turnrate = 5;
        const float maxspeed = 0.1;

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

            //mat.roughness = (-joystick.axes[game.JOY.AXIS.LT]+1)/2;
            //maze.light.color.b = (-joystick.axes[game.JOY.AXIS.LT]+1)/2;
            //maze.light.color.g = maze.light.color.b;
        }
    }
}

//-----------------------------------------------------------------------------

static if(0) {
    auto skybox = new postprocess.SkyBox(
        new render.Cubemap([
            /*
            "engine/stock/unsorted/cubemaps/skybox1/right.png",
            "engine/stock/unsorted/cubemaps/skybox1/left.png",
            "engine/stock/unsorted/cubemaps/skybox1/top.png",
            "engine/stock/unsorted/cubemaps/skybox1/bottom.png",
            "engine/stock/unsorted/cubemaps/skybox1/back.png",
            "engine/stock/unsorted/cubemaps/skybox1/front.png"
            /*/
            "engine/stock/unsorted/cubemaps/skybox2/universe_right.png",
            "engine/stock/unsorted/cubemaps/skybox2/universe_left.png",
            "engine/stock/unsorted/cubemaps/skybox2/universe_top.png",
            "engine/stock/unsorted/cubemaps/skybox2/universe_bottom.png",
            "engine/stock/unsorted/cubemaps/skybox2/universe_back.png",
            "engine/stock/unsorted/cubemaps/skybox2/universe_front.png",
            
            /**/
            ]
        ),
        game.screen.fb
    );
}

//-----------------------------------------------------------------------------

void main()
{
    game.init(800, 600);

    auto pipeline = createPipeline();

    loadmaze(pipeline, grid);

    //-------------------------------------------------------------------------

    pipeline.actors.reportperf;

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

    simple.gameloop(
        50,              // FPS
        &draw,           // draw
        pipeline.actors, // list of actors
        &processevents
    );
}

static if(0)
{

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
}
