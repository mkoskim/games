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
// ...
//
//*****************************************************************************

class Scene : render.BufferedRender
{
    Player player;
    render.Model[] wallshapes, floorshapes, propshapes;

    this(string[] grid)
    {
        loadmodels();
        loadmaze(grid);
        
        light = new render.Light(
            render.Grip.fixed(0, 2, 0),
            vec3(1, 1, 1),
            10,
            0.1
        );
    }

    void loadmodels()
    {
        //---------------------------------------------------------------------
        // Create batches: we create several now just for testing the system.
        //---------------------------------------------------------------------

        auto walls  = addbatch(render.Batch.Solid3D());
        auto props  = addbatch(new render.Batch(walls));
        auto floors = addbatch(new render.Batch(walls));

        auto transparent = addbatch(render.Batch.Transparent3D());
        
        //---------------------------------------------------------------------
        //
        // Load different materials for later use... It would be very nice
        // to have some kind of material database to ease this process...
        //
        //---------------------------------------------------------------------

        auto matCaveWall = new render.Material(
            "engine/stock/tiles/CaveWall/ColorMap.png",
            "engine/stock/tiles/CaveWall/NormalMap.png",
            1.00);

        auto matCrackedPlaster = new render.Material(
            "engine/stock/tiles/CrackedPlaster/ColorMap.png",
            "engine/stock/tiles/CrackedPlaster/NormalMap.png",
            0.95);

        auto matSantaFeStucco = new render.Material(
            //"engine/stock/tiles/SantaFeStucco/ColorMap.png",
            "engine/stock/tiles/CaveWall/ColorMap.png",
            "engine/stock/tiles/SantaFeStucco/NormalMap.png",
            0.95);

        auto matTanStucco = new render.Material(
            //"engine/stock/tiles/SantaFeStucco/ColorMap.png",
            "engine/stock/tiles/TanStucco/ColorMap.png",
            "engine/stock/tiles/TanStucco/NormalMap.png",
            0.95);

        auto matBrickWall = new render.Material(
            "engine/stock/tiles/BrickWall1/ColorMap.png",
            "engine/stock/tiles/BrickWall1/NormalMap.png",
            0.95);

        auto matGraniteWall = new render.Material(
            "engine/stock/tiles/GraniteWall/ColorMap.png",
            "engine/stock/tiles/GraniteWall/NormalMap.png",
            0.95);

        auto matCrustyConcrete = new render.Material(
            "engine/stock/tiles/Concrete/Crusty/ColorMap.png",
            "engine/stock/tiles/Concrete/Crusty/NormalMap.png",
            0.95);

        auto matDirtyConcrete = new render.Material(
            "engine/stock/tiles/Concrete/Dirty/ColorMap.png",
            "engine/stock/tiles/Concrete/Dirty/NormalMap.png",
            0.95);

        auto matCarvedSandstone = new render.Material(
            "engine/stock/tiles/CarvedSandstone/ColorMap.png",
            //"engine/stock/tiles/CaveWall/ColorMap.png",
            //vec3(0.5, 0.4, 0.2),
            "engine/stock/tiles/CarvedSandstone/NormalMap.png",
            0.95);

        auto matAlienCarving = new render.Material(
            //"engine/stock/tiles/AlienCarving/ColorMap.png",
            vec4(0.75, 0.5, 0.25, 1),
            "engine/stock/tiles/AlienCarving/NormalMap.png",
            0.15);

        auto matMetallicAssembly = new render.Material(
            //"engine/stock/tiles/MetallicAssembly/ColorMap.png",
            vec4(0.5, 0.5, 0.5, 1),
            "engine/stock/tiles/MetallicAssembly/NormalMap.png",
            0.15);

        auto matGlass = new render.Material(
            vec4(0.8, 0.8, 0.9, 0.3),
            "engine/stock/tiles/SantaFeStucco/NormalMap.png",
            0.50
        );

        //---------------------------------------------------------------------
        // Load meshes
        //---------------------------------------------------------------------

        auto wallmesh = blob.wavefront.loadmesh("engine/stock/mesh/Cube/CubeWrap.obj");
        auto floormesh = blob.wavefront.loadmesh("engine/stock/mesh/Cube/Floor.obj");
        auto monkeymesh = blob.wavefront.loadmesh("engine/stock/mesh/Suzanne/Suzanne.obj").scale(0.66);
        
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
            floors.upload(floormesh, new render.Material(
                vec4(0.25, 0.25, 0.25, 1),
                matGraniteWall.normalmap,
                0.15
            )),
        ];

        propshapes = [
            /*
            props.upload(monkeymesh, new render.Material(
                vec4(0.75, 0.5, 0.25, 1),
                //matSantaFeStucco.normalmap,
                0.5
            )),
            */
            transparent.upload(monkeymesh, matGlass),
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

    render.Transform root;
    render.Camera cam;

    game.Joystick joystick;
    render.Material* mat;

    this(Scene maze, vec3 pos)
    {
        super();

        this.maze = maze;
        
        root = render.Grip.movable(pos);

        cam = render.Camera.basic3D(0.1, 20, render.Grip.movable(root));

        joystick = game.joysticks[0];
        
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
    /*
    import luad.all;

    auto lua = new LuaState;
    lua.openLibs();

    auto print = lua.get!LuaFunction("print");
    print("Hello, world!");    
    */

    game.init(800, 600);

    auto maze = new Scene(grid);

    //-------------------------------------------------------------------------

    /*
    auto hud = new render.Layer(
        render.shaders.Default2D.create(),
        render.Camera.topleft2D
    );

    auto txtInfo = new TextBox(hud, 2, 2,
        "%info%\n"
        "CAM....: (%cam.x%, %cam.z%)\n"
        "Objects: %drawn% / %total%\n"
        "GL.....: %calls%\n"
        " \n"
        "Mat....: r = %mat.r%\n"
    );

    actors.addcallback(() {
        txtInfo["info"] = game.Profile.info();
        txtInfo["cam.x"] = format("%.1f", maze.player.root.pos.x);
        txtInfo["cam.z"] = format("%.1f", maze.player.root.pos.z);
        txtInfo["drawn"] = format("%d", maze.perf.drawed);
        txtInfo["total"] = format("%d", maze.nodes.length);
        txtInfo["mat.r"] = format("%.2f", maze.mat.roughness);

        import engine.render.util: glcalls;
        txtInfo["calls"] = format("%d", glcalls);
        glcalls = 0;
    });

    //writeln("VBO row size: ", render.Mesh.VERTEX.sizeof);
    //writeln(to!string(glGetString(GL_EXTENSIONS)));
    */

    maze.actors.reportperf;
    
    //-------------------------------------------------------------------------

    void draw()
    {
        maze.draw();
        //hud.draw();
    }

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,             // FPS
        &draw,          // draw
        maze.actors,    // list of actors

        (SDL_Event* event) {
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

