//*****************************************************************************
//
// Wolfenstein-style FPS project for game engine experimenting.
//
// Wolfenstein style FPS is "pseudo-3D", as all action still happens in
// two dimensions as in pacman. This project is mainly used to experiment
// things like materials and lighting.
//
// This game can be later used to experiment how to implement moving
// in three dimensions.
//
//*****************************************************************************

import engine;

static import std.random;
import std.stdio: writeln;

//*****************************************************************************
//
// Maze
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
// Sketching render pipelining:
//
// 1) We need shaders, or at least their interfaces.
// 2) Then we load assets
// 3) And place them to node groups
//
//*****************************************************************************

class Scene : scene3d.Pipeline3D
{
    Player player;
    scene3d.Model[] wallshapes, floorshapes, propshapes;

    postprocess.SkyBox skybox;

    this(string[] grid)
    {
        loadmodels();
        loadmaze(grid);

        light = new scene3d.Light(
            scene3d.Grip.fixed(0, 2, 0),
            vec3(1, 1, 1),
            10,
            0.1
        );
        
        skybox = new postprocess.SkyBox(
            new render.Cubemap([
                /*
                "engine/stock/cubemaps/skybox1/right.png",
                "engine/stock/cubemaps/skybox1/left.png",
                "engine/stock/cubemaps/skybox1/top.png",
                "engine/stock/cubemaps/skybox1/bottom.png",
                "engine/stock/cubemaps/skybox1/back.png",
                "engine/stock/cubemaps/skybox1/front.png"
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

    void loadmodels()
    {
        //---------------------------------------------------------------------
        // Create batches: we create several now just for testing the system.
        //---------------------------------------------------------------------

        //auto solidshader = scene3d.shaders.Flat3D.create();
        auto solidshader = scene3d.Shader.Default3D();

        //*
        solidshader.options["fog.enabled"] = false;
        solidshader.options["fog.start"] = 10.0;
        solidshader.options["fog.end"]   = 20.0;
        solidshader.options["fog.color"] = vec4(0.0, 0.0, 0.0, 1);
        /**/
        //solidshader.options["fog.color"] = vec4(0.45, 0.45, 0.75, 1);
        //solidshader.options["fog.color"] = vec4(0.45, 0.45, 0.45, 1);
        //solidshader.options["fog.color"] = vec4(1.0, 1.0, 1.0, 1);

        auto solidstate = scene3d.State.Solid3D(solidshader);

        auto walls  = addbatch(scene3d.Batch.Solid3D(solidstate));
        auto props  = addbatch(scene3d.Batch.Solid3D(solidstate));
        auto floors = addbatch(solidstate, scene3d.Batch.Mode.unsorted);

        //props.state.target = new render.Framebuffer();

        //props.state.options["useQuants"] = 8;
        //floors.state.options["useQuants"] = false;

        auto transparent = addbatch(scene3d.Batch.Transparent3D(solidshader));

        //---------------------------------------------------------------------
        // Texture loader(s)
        //---------------------------------------------------------------------

        auto colormap = new render.Texture.Loader();
        colormap.mipmap = true;
        colormap.filtering.min = GL_LINEAR_MIPMAP_LINEAR;
        colormap.compress = true;

        auto normalmap = new render.Texture.Loader();
        normalmap.mipmap = true;
        normalmap.filtering.min = GL_LINEAR_MIPMAP_LINEAR;

        //---------------------------------------------------------------------
        //
        // Load different materials for later use... It would be very nice
        // to have some kind of material database to ease this process...
        //
        //---------------------------------------------------------------------

        auto matCaveWall = new scene3d.Material(
            colormap("engine/stock/unsorted/tiles/CaveWall/ColorMap.png"),
            normalmap("engine/stock/unsorted/tiles/CaveWall/NormalMap.png"),
            1.00);

        auto matCrackedPlaster = new scene3d.Material(
            colormap("engine/stock/unsorted/tiles/CrackedPlaster/ColorMap.png"),
            normalmap("engine/stock/unsorted/tiles/CrackedPlaster/NormalMap.png"),
            0.95);

        auto matSantaFeStucco = new scene3d.Material(
            //"engine/stock/tiles/SantaFeStucco/ColorMap.png",
            colormap("engine/stock/unsorted/tiles/CaveWall/ColorMap.png"),
            normalmap("engine/stock/unsorted/tiles/SantaFeStucco/NormalMap.png"),
            0.95);

        auto matTanStucco = new scene3d.Material(
            //"engine/stock/tiles/SantaFeStucco/ColorMap.png",
            colormap("engine/stock/unsorted/tiles/TanStucco/ColorMap.png"),
            normalmap("engine/stock/unsorted/tiles/TanStucco/NormalMap.png"),
            0.95);

        auto matBrickWall = new scene3d.Material(
            colormap("engine/stock/unsorted/tiles/BrickWall1/ColorMap.png"),
            normalmap("engine/stock/unsorted/tiles/BrickWall1/NormalMap.png"),
            0.95);

        auto matGraniteWall = new scene3d.Material(
            colormap("engine/stock/unsorted/tiles/GraniteWall/ColorMap.png"),
            normalmap("engine/stock/unsorted/tiles/GraniteWall/NormalMap.png"),
            0.95);

        auto matCrustyConcrete = new scene3d.Material(
            colormap("engine/stock/unsorted/tiles/Concrete/Crusty/ColorMap.png"),
            normalmap("engine/stock/unsorted/tiles/Concrete/Crusty/NormalMap.png"),
            0.95);

        auto matDirtyConcrete = new scene3d.Material(
            colormap("engine/stock/unsorted/tiles/Concrete/Dirty/ColorMap.png"),
            normalmap("engine/stock/unsorted/tiles/Concrete/Dirty/NormalMap.png"),
            0.95);

        auto matCarvedSandstone = new scene3d.Material(
            colormap("engine/stock/unsorted/tiles/CarvedSandstone/ColorMap.png"),
            //"engine/stock/tiles/CaveWall/ColorMap.png",
            //vec3(0.5, 0.4, 0.2),
            normalmap("engine/stock/unsorted/tiles/CarvedSandstone/NormalMap.png"),
            0.95);

        auto matAlienCarving = new scene3d.Material(
            //"engine/stock/tiles/AlienCarving/ColorMap.png",
            colormap(vec4(0.75, 0.5, 0.25, 1)),
            normalmap("engine/stock/unsorted/tiles/AlienCarving/NormalMap.png"),
            0.15);

        auto matMetallicAssembly = new scene3d.Material(
            //"engine/stock/tiles/MetallicAssembly/ColorMap.png",
            colormap(vec4(0.5, 0.5, 0.5, 1)),
            normalmap("engine/stock/unsorted/tiles/MetallicAssembly/NormalMap.png"),
            0.15);

        auto matGlass = new scene3d.Material(
            colormap(vec4(0.8, 0.8, 0.9, 0.3)),
            normalmap("engine/stock/unsorted/tiles/SantaFeStucco/NormalMap.png"),
            0.50
        );

        //---------------------------------------------------------------------
        // Load meshes
        //---------------------------------------------------------------------

        auto wallmesh = blob.wavefront.loadmesh("engine/stock/unsorted/mesh/Cube/CubeWrap.obj");
        auto floormesh = blob.wavefront.loadmesh("engine/stock/unsorted/mesh/Cube/Floor.obj");
        auto monkeymesh = blob.wavefront.loadmesh("engine/stock/unsorted/mesh/Suzanne/Suzanne.obj").scale(0.66);
        
        //---------------------------------------------------------------------
        // Create models to batches
        //---------------------------------------------------------------------
        
        wallshapes = [
            walls.upload(wallmesh, matCaveWall),
            walls.upload(wallmesh, matBrickWall),
            walls.upload(wallmesh, matDirtyConcrete),
            walls.upload(wallmesh, matMetallicAssembly),
            walls.upload(wallmesh, matAlienCarving),
        ];

        floorshapes = [
            floors.upload(floormesh, matGraniteWall),
            floors.upload(floormesh, new scene3d.Material(
                colormap(vec4(0.25, 0.25, 0.25, 1)),
                matGraniteWall.normalmap,
                0.15
            )),
        ];

        propshapes = [
            /*
            props.upload(monkeymesh, new scene3d.Material(
                vec4(0.75, 0.5, 0.25, 1),
                //matSantaFeStucco.normalmap,
                0.5
            )),
            /*/
            transparent.upload(monkeymesh, matGlass),
            /**/
        ];
    }

    void loadmaze(string[] grid)
    {
        foreach(y, line; grid)
        {
            foreach(x, c; line)
            {
                vec3 pos = vec3(2*x, 0, 2*(cast(int)y - cast(int)grid.length));
                switch(c)
                {
                    case '1', '2', '3', '4', '5':
                        nodes.add(pos, wallshapes[c - '1']);
                        break;
                    case '#':
                        nodes.add(pos, wallshapes[0]);
                        break;
                    case ' ':
                        nodes.add(pos, floorshapes[0]);
                        break;
                    case 'n':
                        nodes.add(pos, floorshapes[1]);
                        break;
                    case 'X':
                        nodes.add(pos, propshapes[0]);
                        goto case ' ';
                    case '@':
                        player = new Player(this, pos); 
                        goto case ' ';
                    default: throw new Exception("Unknown char: " ~ c);
                }
            }
        }
    }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

class Player : game.Fiber
{
    Scene maze;

    scene3d.Transform root;
    scene3d.Camera cam;

    game.Joystick joystick;
    scene3d.Material* mat;

    this(Scene maze, vec3 pos)
    {
        super();

        this.maze = maze;
        
        root = scene3d.Grip.movable(pos);

        cam = scene3d.Camera.basic3D(0.1, 20, scene3d.Grip.movable(root));

        joystick = game.controller;
        
        mat = &maze.propshapes[0].material;

        maze.cam = cam;
        this.maze.actors.add(this);
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
                forward * joystick.axes[game.JOY.AXIS.LY] * maxspeed +
                strafe  * joystick.axes[game.JOY.AXIS.LX] * maxspeed;

            root.grip.rot.y -= joystick.axes[game.JOY.AXIS.RX] * turnrate;
            cam.grip.rot.x = clamp(
                cam.grip.rot.x - joystick.axes[game.JOY.AXIS.RY] * turnrate,
                -30, 30
            );

            mat.roughness = (-joystick.axes[game.JOY.AXIS.LT]+1)/2;
            //maze.light.color.b = (-joystick.axes[game.JOY.AXIS.LT]+1)/2;
            //maze.light.color.g = maze.light.color.b;
        }
    }
}

//-----------------------------------------------------------------------------

void main()
{
    game.init(800, 600);

    auto maze = new Scene(grid);

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

    maze.actors.reportperf;

    //-------------------------------------------------------------------------

    void draw()
    {
        maze.draw();
        maze.skybox.draw(maze.cam.mView(), maze.cam.mProjection());
        //hud.draw();
    }

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,             // FPS
        &draw,          // draw
        maze.actors,    // list of actors

        (SDL_Event event) {
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
    );
}

