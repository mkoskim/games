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
// Create batch group, and assign models to batches
//
//*****************************************************************************

class MazeBatch : render.BatchGroup
{

    render.Model[] wallshapes, floorshapes, propshapes;

    this()
    {
        //---------------------------------------------------------------------
        //
        // Load different materials for later use... It would be very nice
        // to have some kind of material database to ease this process...
        //
        //---------------------------------------------------------------------

        auto matCaveWall = new render.Material(
            new render.Texture("engine/stock/tiles/CaveWall/ColorMap.png"),
            new render.Texture("engine/stock/tiles/CaveWall/NormalMap.png"),
            1.00);

        auto matCrackedPlaster = new render.Material(
            new render.Texture("engine/stock/tiles/CrackedPlaster/ColorMap.png"),
            new render.Texture("engine/stock/tiles/CrackedPlaster/NormalMap.png"),
            0.95);

        auto matSantaFeStucco = new render.Material(
            //new render.Texture("engine/stock/tiles/SantaFeStucco/ColorMap.png"),
            new render.Texture("engine/stock/tiles/CaveWall/ColorMap.png"),
            new render.Texture("engine/stock/tiles/SantaFeStucco/NormalMap.png"),
            0.95);

        auto matTanStucco = new render.Material(
            //new render.Texture("engine/stock/tiles/SantaFeStucco/ColorMap.png"),
            new render.Texture("engine/stock/tiles/TanStucco/ColorMap.png"),
            new render.Texture("engine/stock/tiles/TanStucco/NormalMap.png"),
            0.95);

        auto matBrickWall = new render.Material(
            new render.Texture("engine/stock/tiles/BrickWall1/ColorMap.png"),
            new render.Texture("engine/stock/tiles/BrickWall1/NormalMap.png"),
            0.95);

        auto matGraniteWall = new render.Material(
            new render.Texture("engine/stock/tiles/GraniteWall/ColorMap.png"),
            new render.Texture("engine/stock/tiles/GraniteWall/NormalMap.png"),
            0.95);

        auto matCrustyConcrete = new render.Material(
            new render.Texture("engine/stock/tiles/Concrete/Crusty/ColorMap.png"),
            new render.Texture("engine/stock/tiles/Concrete/Crusty/NormalMap.png"),
            0.95);

        auto matDirtyConcrete = new render.Material(
            new render.Texture("engine/stock/tiles/Concrete/Dirty/ColorMap.png"),
            new render.Texture("engine/stock/tiles/Concrete/Dirty/NormalMap.png"),
            0.95);

        auto matCarvedSandstone = new render.Material(
            new render.Texture("engine/stock/tiles/CarvedSandstone/ColorMap.png"),
            //new render.Texture("engine/stock/tiles/CaveWall/ColorMap.png"),
            //vec3(0.5, 0.4, 0.2),
            new render.Texture("engine/stock/tiles/CarvedSandstone/NormalMap.png"),
            0.95);

        auto matAlienCarving = new render.Material(
            //new render.Texture("engine/stock/tiles/AlienCarving/ColorMap.png"),
            vec4(0.75, 0.5, 0.25, 1),
            new render.Texture("engine/stock/tiles/AlienCarving/NormalMap.png"),
            0.15);

        auto matMetallicAssembly = new render.Material(
            //new render.Texture("engine/stock/tiles/MetallicAssembly/ColorMap.png"),
            vec4(0.5, 0.5, 0.5, 1),
            new render.Texture("engine/stock/tiles/MetallicAssembly/NormalMap.png"),
            0.15);

        //---------------------------------------------------------------------
        // Load meshes
        //---------------------------------------------------------------------

        auto wallmesh = blob.wavefront.loadmesh("engine/stock/mesh/Cube/CubeWrap.obj");
        auto floormesh = blob.wavefront.loadmesh("engine/stock/mesh/Cube/Floor.obj");
        auto monkeymesh = blob.wavefront.loadmesh("engine/stock/mesh/Suzanne/Suzanne.obj").scale(0.66);
        
        //---------------------------------------------------------------------
        // Create batches: we create several now just for testing the system.
        //---------------------------------------------------------------------

        auto rs = new render.RenderState3D();

        auto walls  = addbatch(new render.Batch(rs));
        auto props  = addbatch(new render.Batch(rs));
        auto floors = addbatch(new render.Batch(rs));
        
        //---------------------------------------------------------------------
        // Create models to batches
        //---------------------------------------------------------------------
        
        wallshapes = [
            walls.upload(wallmesh, matCaveWall),
            walls.upload(wallmesh, matBrickWall),
            walls.upload(wallmesh, matDirtyConcrete),
            walls.upload(wallmesh, matMetallicAssembly),
            walls.upload(wallmesh, matAlienCarving),
            //matCrackedPlaster
            //matCrustyConcrete
            //matDirtyConcrete
            //matCaveWall
            //matBrickWall
            //matCarvedSandstone
            //matAlienCarving
            //matMetallicAssembly
        ];

        auto floormat = matGraniteWall;

        floorshapes = [
            floors.upload(floormesh, matGraniteWall),
            floors.upload(floormesh, new render.Material(
                vec4(0.25, 0.25, 0.25, 1),
                floormat.normalmap,
                0.15
            )),
        ];

        propshapes = [
            props.upload(monkeymesh, new render.Material(
                vec4(0.75, 0.5, 0.25, 1),
                //matSantaFeStucco.normalmap,
                0.5
            )),
        ];
    }
}

//-----------------------------------------------------------------------------

class Maze
{
    Player player;
    render.Light light;
    MazeBatch batches;
    render.BasicNodeGroup nodes;

    void draw()
    {
        batches.clear();
        nodes.collect(player.cam, batches);
        
        // TODO: Hack! Design light subsystem
        auto rs = batches.batches[0].rs;
        rs.activate();
        if(light) rs.shader.light(light);

        batches.draw(player.cam);
    }

    this(string[] grid)
    {
        light = new render.Light(
            vec3(0, 2, 0),
            vec3(1, 1, 1),
            10,
            0.1
        );

        batches = new MazeBatch();
        nodes = new render.BasicNodeGroup();

        //---------------------------------------------------------------------

        foreach(y, line; grid)
        {
            foreach(x, c; line)
            {
                vec3 pos = vec3(2*x, 0, 2*(cast(int)y - cast(int)grid.length));
                switch(c)
                {
                    case '1', '2', '3', '4', '5':
                        nodes.add(pos, batches.wallshapes[c - '1']);
                        break;
                    case '#':
                        nodes.add(pos, batches.wallshapes[0]);
                        break;
                    case ' ':
                        nodes.add(pos, batches.floorshapes[0]);
                        break;
                    case 'n':
                        nodes.add(pos, batches.floorshapes[1]);
                        break;
                    case 'X':
                        nodes.add(pos, batches.propshapes[0]);
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
    Maze maze;

    render.Bone root;
    render.Camera cam;

    game.Joystick joystick;
    render.Material* mat;

    this(Maze maze, vec3 pos)
    {
        super();

        this.maze = maze;

        root = new render.Bone(pos);

        cam = render.Camera.basic3D(0.1, 20, new render.Bone(root));

        joystick = game.joysticks[0];
        
        mat = &maze.batches.propshapes[0].material;
    }

    override void run()
    {
        const float turnrate = 5;
        const float maxspeed = 0.1;

        for(;;nextframe())
        {
            vec3 forward = (root.mModel() * vec4( 0, 0, +1, 0)).xyz;
            vec3 strafe  = (root.mModel() * vec4(+1, 0,  0, 0)).xyz;

            root.pos +=
                forward * joystick.axes[game.JOY.AXIS.LY] * maxspeed +
                strafe  * joystick.axes[game.JOY.AXIS.LX] * maxspeed;

            root.rot.y -= joystick.axes[game.JOY.AXIS.RX] * turnrate;
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

    auto maze = new Maze(grid);

    //-------------------------------------------------------------------------

    auto actors = new game.FiberQueue();

    //-------------------------------------------------------------------------

    actors.add(maze.player);

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

    actors.reportperf;
    
    //-------------------------------------------------------------------------

    void draw()
    {
        maze.draw();
        //hud.draw();
    }

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,         // FPS
        &draw,      // draw
        actors,     // list of actors

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

