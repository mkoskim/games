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
import std.stdio;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

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

//-----------------------------------------------------------------------------

class Maze : render.Scene
{
    render.Material* mat;
    Player player;

    this(string[] grid)
    {
        super();
        //super(render.shaders.Toon3D.create());

        //---------------------------------------------------------------------

        light = new render.Light(
            vec3(0, 2, 0),
            vec3(1, 1, 1),
            10,
            0.1
        );

        //---------------------------------------------------------------------
        // Load different materials for later use
        //---------------------------------------------------------------------

        auto matCaveWall = new render.Material(
            new render.Texture("engine/stock/tiles/CaveWall/ColorMap.png"),
            new render.Texture("engine/stock/tiles/CaveWall/NormalMap.png"),
            1.00);

        auto matCrackedPlaster = new render.Material(
            new render.Texture("engine/stock/tiles/CrackedPlaster/ColorMap.png"),
            new render.Texture("engine/stock/tiles/CrackedPlaster/NormalMap.png"),
            0.5);

        auto matSantaFeStucco = new render.Material(
            //new render.Texture("engine/stock/tiles/SantaFeStucco/ColorMap.png"),
            new render.Texture("engine/stock/tiles/CaveWall/ColorMap.png"),
            new render.Texture("engine/stock/tiles/SantaFeStucco/NormalMap.png"),
            0.85);

        auto matTanStucco = new render.Material(
            //new render.Texture("engine/stock/tiles/SantaFeStucco/ColorMap.png"),
            new render.Texture("engine/stock/tiles/TanStucco/ColorMap.png"),
            new render.Texture("engine/stock/tiles/TanStucco/NormalMap.png"),
            0.85);

        auto matBrickWall = new render.Material(
            new render.Texture("engine/stock/tiles/BrickWall1/ColorMap.png"),
            new render.Texture("engine/stock/tiles/BrickWall1/NormalMap.png"),
            0.85);

        auto matGraniteWall = new render.Material(
            new render.Texture("engine/stock/tiles/GraniteWall/ColorMap.png"),
            new render.Texture("engine/stock/tiles/GraniteWall/NormalMap.png"),
            0.85);

        auto matCrustyConcrete = new render.Material(
            new render.Texture("engine/stock/tiles/Concrete/Crusty/ColorMap.png"),
            new render.Texture("engine/stock/tiles/Concrete/Crusty/NormalMap.png"),
            0.85);

        auto matDirtyConcrete = new render.Material(
            new render.Texture("engine/stock/tiles/Concrete/Dirty/ColorMap.png"),
            new render.Texture("engine/stock/tiles/Concrete/Dirty/NormalMap.png"),
            0.85);

        auto matCarvedSandstone = new render.Material(
            new render.Texture("engine/stock/tiles/CarvedSandstone/ColorMap.png"),
            //new render.Texture("engine/stock/tiles/CaveWall/ColorMap.png"),
            //vec3(0.5, 0.4, 0.2),
            new render.Texture("engine/stock/tiles/CarvedSandstone/NormalMap.png"),
            0.85);

        auto matAlienCarving = new render.Material(
            new render.Texture("engine/stock/tiles/AlienCarving/ColorMap.png"),
            //vec3(0.75, 0.5, 0.25),
            new render.Texture("engine/stock/tiles/AlienCarving/NormalMap.png"),
            0.15);

        auto matMetallicAssembly = new render.Material(
            new render.Texture("engine/stock/tiles/MetallicAssembly/ColorMap.png"),
            //vec3(0.5, 0.5, 0.5),
            new render.Texture("engine/stock/tiles/MetallicAssembly/NormalMap.png"),
            0.15);

        //---------------------------------------------------------------------

        auto wallmesh = shader.upload(blob.wavefront.loadmesh("engine/stock/mesh/Cube/CubeWrap.obj"));

        render.Shape wallshape[] = [
            new render.Shape(wallmesh, matCaveWall),
            new render.Shape(wallmesh, matBrickWall),
            new render.Shape(wallmesh, matDirtyConcrete),
            new render.Shape(wallmesh, matMetallicAssembly),
            new render.Shape(wallmesh, matAlienCarving),
            //matCrackedPlaster
            //matCrustyConcrete
            //matDirtyConcrete
            //matCaveWall
            //matBrickWall
            //matCarvedSandstone
            //matAlienCarving
            //matMetallicAssembly
        ];

        auto floorshape = new render.Shape(
            shader.upload(blob.wavefront.loadmesh("engine/stock/mesh/Cube/Floor.obj")),
            //matCaveWall
            //matCarvedSandstone
            //matCrustyConcrete
            //matDirtyConcrete
            //matAlienCarving
            //matCrackedPlaster
            //matBrickWall
            //matTanStucco
            //matSantaFeStucco
            matGraniteWall
        );

        auto floorshape2 = new render.Shape(
            floorshape.vao,
            new render.Material(
                vec3(0.25, 0.25, 0.25),
                //matCrackedPlaster.normalmap,
                floorshape.material.normalmap,
                0.15
            )
        );

        auto monkeyshape = new render.Shape(
            shader.upload(
                blob.wavefront.loadmesh("engine/stock/mesh/Suzanne/Suzanne.obj")
                .scale(0.66)
            ),
            new render.Material(
                vec3(0.75, 0.5, 0.25),
                matSantaFeStucco.normalmap,
                0.5
            )
        );

        mat = &monkeyshape.material;

        //---------------------------------------------------------------------

        foreach(y, line; grid)
        {
            foreach(x, c; line)
            {
                vec3 pos = vec3(2*x, 0, 2*(cast(int)y - cast(int)grid.length));
                switch(c)
                {
                    case '1', '2', '3', '4', '5':
                        add(pos, wallshape[c - '1']);
                        break;
                    case '#':
                        add(pos, wallshape[0]);
                        break;
                    case ' ':
                        add(pos, floorshape);
                        break;
                    case 'n':
                        add(pos, floorshape2);
                        break;
                    case 'X':
                        add(pos, monkeyshape);
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

    this(Maze maze, vec3 pos)
    {
        super();

        this.maze = maze;

        root = new render.Bone(pos);

        cam = render.Camera.basic3D(0.1, 20, new render.Bone(root));

        joystick = game.joysticks[0];
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

            //maze.mat.roughness = (-joystick.axes[game.JOY.AXIS.LT]+1)/2;
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

    auto hud = new render.Layer(
        render.shaders.Default2D.create(),
        render.Camera.topleft2D
    );

    auto txtPerf   = new TextBox(hud, 2, 2 + 0*12, "%info%");
    auto txtCamPos = new TextBox(hud, 2, 2 + 1*12, "CAM....: (%x%, %z%)");
    auto txtDrawn  = new TextBox(hud, 2, 2 + 2*12, "Objects: %drawn% / %total%");
    auto txtGL     = new TextBox(hud, 2, 2 + 3*12, "GL.....: %calls%");
    auto txtMat    = new TextBox(hud, 2, 2 + 4*12, "Mat....: r = %r%");

    actors.addcallback(() {
        txtPerf["info"] = game.Profile.info();
        txtCamPos["x"] = format("%.1f", maze.player.root.pos.x);
        txtCamPos["z"] = format("%.1f", maze.player.root.pos.z);
        txtDrawn["drawn"] = format("%d", maze.perf.drawed);
        txtDrawn["total"] = format("%d", maze.instances.length);
        txtMat["r"] = format("%.2f", maze.mat.roughness);

        import engine.render.util: glcalls;
        txtGL["calls"] = format("%d", glcalls);
        glcalls = 0;
    });

    //writeln("VBO row size: ", render.Mesh.VERTEX.sizeof);
    //writeln(to!string(glGetString(GL_EXTENSIONS)));

    //-------------------------------------------------------------------------

    void draw()
    {
        maze.draw(maze.player.cam);
        hud.draw();
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
                    case SDLK_w: maze.shader.fill = !maze.shader.fill; break;
                    case SDLK_e: maze.shader.enabled = !maze.shader.enabled; break;
                    case SDLK_r: {
                        static bool normmaps = true;
                        normmaps = !normmaps;
                        maze.shader.activate();
                        maze.shader.uniform("useNormalMapping", normmaps);
                    } break;
                }
            }
            return true;
        }
    );
}

