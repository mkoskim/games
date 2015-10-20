//*****************************************************************************
//
// Cylinderium - "Uridium" with rolling mother ship
//
//*****************************************************************************

import std.stdio;
import std.math: sgn;
import random = std.random: uniform;

import engine;

//*****************************************************************************
//
// Parameters for game world
//
//*****************************************************************************

const int GRID_H = 24;
const float RADIUS = (GRID_H/PI) - 0.05;
const float MAX_HEIGHT = 2 * RADIUS;
const float CAM_HEIGHT = 3.5 * RADIUS;

//*****************************************************************************
//
// Star field: This does not work currently - points are not colored.
//
//*****************************************************************************

//*****************************************************************************
//
// Create game assets
//
//*****************************************************************************

class Scene : scene3d.Pipeline3D
{
    scene3d.Model floor, wall, tower, playership, star;
    scene3d.Batch solid, flat;

    MotherShip mothership;

    this()
    {
        super();

        //---------------------------------------------------------------------

        flat  = scene3d.Batch.Solid3D(scene3d.shaders.Flat3D.create());
        solid = scene3d.Batch.Solid3D();

        addbatch(solid);
        addbatch(flat);

        //---------------------------------------------------------------------
        // Black-yellow stripes texture
        //---------------------------------------------------------------------

        auto warnbmp = new Bitmap(32, 32);
        foreach(x; 0 .. warnbmp.width) foreach(y; 0 .. warnbmp.height) {
            warnbmp.putpixel(x, y,
                (((x+y) % 32) < 16) ? vec4(1, 1, 0, 1) : vec4(0, 0, 0, 1)
            );
        }

        //---------------------------------------------------------------------

        floor = solid.upload(
            blob.wavefront.loadmesh("data/mesh/Floor.obj").move(0, RADIUS, 0),
            new scene3d.Material(vec4(0.5, 0.5, 0.5, 1), 0.85)
        );

        wall = solid.upload(
            blob.wavefront.loadmesh("data/mesh/Wall.obj").move(0, RADIUS, 0),
            new scene3d.Material(warnbmp.surface, 0.75)
        );

        tower = solid.upload(
            blob.wavefront.loadmesh("data/mesh/Guntower.obj").move(0, RADIUS, 0),
            new scene3d.Material(vec4(1, 0, 0, 1), 0.75)
        );

        //---------------------------------------------------------------------

        star = flat.upload(
            blob.wavefront.loadmesh("engine/stock/mesh/Cube/Cube.obj").scale(0.1),
            new scene3d.Material(vec4(1, 1, 0.75, 1), 0.75)
        );

        //---------------------------------------------------------------------

        playership = solid.upload(
            blob.wavefront.loadmesh("data/mesh/Ship.obj"), //.scale(1.25)
            new scene3d.Material(vec4(0.4, 0.4, 0.7, 1))
        );

        //---------------------------------------------------------------------

        light = new scene3d.Light(
            scene3d.Grip.fixed(0, 10, 0),
            vec3(1, 1, 1),
            40,
            0.2
        );

        //---------------------------------------------------------------------

        mothership = new MotherShip();
        addgroup(mothership);
    }
}

//*****************************************************************************
//
// String grids to construct mother ships
//
//*****************************************************************************

static class grid
{
    static string[] greeting = [
//       0        1         2         3         4         5         6
//       123456789|123456789|123456789|123456789|123456789|123456789|
        "|  |  XX X X X   X X  X XX  XXX XX  X X  X X   X O###",
        "|  | X   X X X   X XX X X X X   X X X X  X XX XX |   ",
        "|--O X    X  X   X X XX X X XX  XX  X X  X X X X |   ",
        "|  | X    X  X   X X  X X X X   X X X X  X X   X |   ",
        "|  |  XX  X  XXX X X  X XX  XXX X X X  XX  X   X O###",
        "|  |                                             |  |",
        "|  |--------------------O###O------------------------",
        "|  |                                             |  |",

        "|  |  XX X X X   X X  X XX  XXX XX  X X  X X   X O###",
        "|  | X   X X X   X XX X X X X   X X X X  X XX XX |   ",
        "|--O X    X  X   X X XX X X XX  XX  X X  X X X X |   ",
        "|  | X    X  X   X X  X X X X   X X X X  X X   X |   ",
        "|  |  XX  X  XXX X X  X XX  XXX X X X  XX  X   X O###",
        "|  |                                             |  |",
        "|  |--------------------O###O------------------------",
        "|  |                                             |  |",

        "|  |  XX X X X   X X  X XX  XXX XX  X X  X X   X O###",
        "|  | X   X X X   X XX X X X X   X X X X  X XX XX |   ",
        "|--O X    X  X   X X XX X X XX  XX  X X  X X X X |   ",
        "|  | X    X  X   X X  X X X X   X X X X  X X   X |   ",
        "|  |  XX  X  XXX X X  X XX  XXX X X X  XX  X   X O###",
        "|  |                                             |  |",
        "|  |--------------------O###O------------------------",
        "|  |                                             |  |",
    ];
}

//*****************************************************************************
//
// Mother ship
//
//*****************************************************************************

class MotherShip : scene3d.BasicNodeGroup
{
    float length = 0;

    this() { super(); }
    
    void createStars(Scene scene, int count, float minx, float maxx, float minz, float maxz)
    {
        foreach(i; 0 .. count)
        {
            float angle = random.uniform(0, 360)*(2*PI/360);
            float dist  = random.uniform(minz, maxz);

            vec3 pos = vec3(
                random.uniform(minx, maxx),
                dist*cos(angle),
                dist*sin(angle)
            );
            add(pos, scene.star);
        }
    }

    void load(Scene scene, string[] grid)
    {
        clear();

        foreach(y, line; grid)
        {
            foreach(x, c; line)
            {
                vec3 pos = vec3(2*x, 0, 0);
                vec3 rot = vec3(360.0/GRID_H*y, 0, 0);

                auto grip = scene3d.Grip.fixed(pos, rot);

                length = max(length, pos.x);

                switch(c)
                {
                    case '|':
                    case '-':
                    case 'X': add(grip, scene.floor); break;
                    case '#': add(grip, scene.wall); break;
                    case 'O': add(grip, scene.tower); break;

                    case ' ': break;
                    default: throw new Exception("Unknown char: " ~ c);
                }
            }
        }

        createStars(
            scene,
            500,
            -75, length + 75,
            MAX_HEIGHT + 0.5, 8*MAX_HEIGHT
        );
    }
}

//*****************************************************************************
//
// Player
//
//*****************************************************************************

class Player : game.Fiber
{
    scene3d.Transform root, shipframe;
    scene3d.Node ship;
    scene3d.Camera cam;

    game.Joystick joystick;
    float MINX, MAXX;

    //-------------------------------------------------------------------------

    this(Scene scene)
    {
        super(scene.actors);

        //---------------------------------------------------------------------

        joystick = game.joysticks[0];

        MINX = -10;
        MAXX = scene.mothership.length + 10;

        //---------------------------------------------------------------------

        root = scene3d.Grip.movable(-40, 0, 0);
        shipframe = scene3d.Grip.movable(root, vec3(0, RADIUS + 0.4, 0));

        ship = scene.nodes.add(scene3d.Grip.movable(shipframe), scene.playership);
        ship.grip.rot.x = 360;

        //---------------------------------------------------------------------

        cam = scene3d.Camera.basic3D(
            CAM_HEIGHT - MAX_HEIGHT, 100,
            scene3d.Grip.movable(
                root,
                vec3(7.5, CAM_HEIGHT, 0),
                vec3(-90, 0, 0)
            )
        );
        
        scene.cam = cam;
    }

    //-------------------------------------------------------------------------

    override void run()
    {
        const float maxrot = 2.5;
        const float maxspeed = 0.5;

        float speed = maxspeed*0.5;
        float delta = 0.033;

        void rotate()
        {
            root.grip.rot.x += joystick.axes[game.JOY.AXIS.LY] * maxrot;

            shipframe.grip.rot.x =  joystick.axes[game.JOY.AXIS.LY] * 30;	// "Roll"
            shipframe.grip.rot.z = -joystick.axes[game.JOY.AXIS.LX] * 45;	// "Pitch"
        }

        void checkturn()
        {
            if(speed < -0.1 || speed > 0.1) {
                root.grip.pos.x += speed;
                return;
            }

            speed = sgn(speed)*0.1;
            int steps = 25;
            float d = -sgn(speed)*0.2 / (steps);
            for(int i = 0; i < steps; i++)
            {
                cam.grip.pos.x  = (speed*10) * 7.5;
                ship.grip.rot.z += 180.0/steps;
                if(ship.grip.rot.z >= 360) ship.grip.rot.z -= 360;
                root.grip.pos.x += speed;
                speed += d*1;
                if(i < steps-1) nextframe();
                rotate();
            }
        }

        for(;;nextframe())
        {
            rotate();

            if(ship.grip.rot.x < ship.grip.rot.z) ship.grip.rot.x += min(8, ship.grip.rot.z - ship.grip.rot.x);
            if(ship.grip.rot.x > ship.grip.rot.z) ship.grip.rot.x -= min(8, ship.grip.rot.x - ship.grip.rot.z);

            if(root.grip.pos.x < MINX)
            {
                if(speed < maxspeed*0.5) speed += delta;
            }
            else if(root.grip.pos.x > MAXX)
            {
                if(speed > -maxspeed*0.5) speed -= delta;
            }
            else
            {
                speed += joystick.axes[game.JOY.AXIS.LX] * delta;

                if(speed > maxspeed) speed = maxspeed;
                if(speed < -maxspeed) speed = -maxspeed;
            }

            checkturn();

            cam.grip.pos.y += joystick.axes[game.JOY.AXIS.RY] * 0.5;
        }
    }
}

//*****************************************************************************
//
// Main
//
//*****************************************************************************

void main()
{
    game.init(800, 600);

    auto scene = new Scene();

    scene.mothership.load(scene, grid.greeting);

    //-------------------------------------------------------------------------
    // Player
    //-------------------------------------------------------------------------

    auto player = new Player(scene);

    //-------------------------------------------------------------------------
    // HUD
    //-------------------------------------------------------------------------

    /*
    auto hud = new render.Layer(
        render.shaders.Default2D.create(),
        render.Camera.topleft2D
    );

    auto txtPerf   = new TextBox(hud, 2, 2 + 0*12, "%info%");
    auto txtGL     = new TextBox(hud, 2, 2 + 1*12, "GL.....: calls = %calls%");
    auto txtDrawn  = new TextBox(hud, 2, 2 + 2*12, "Objects: %drawn% / %total%");

    void updateHUD()
    {
        txtPerf["info"] = game.Profile.info();

        import engine.render.util: glcalls;
        txtGL["calls"] = format("%d", glcalls);
        glcalls = 0;

        txtDrawn["drawn"] = format("%d", ship.perf.drawed);
        txtDrawn["total"] = format("%d", ship.instances.length);
    }

    actors.addcallback(&updateHUD);
    */
    
    scene.actors.reportperf;
    
    //-------------------------------------------------------------------------

    auto skybox = new postprocess.SkyBox(
        new render.Cubemap([
            "engine/stock/cubemaps/skybox2/universe_right.png",
            "engine/stock/cubemaps/skybox2/universe_left.png",
            "engine/stock/cubemaps/skybox2/universe_top.png",
            "engine/stock/cubemaps/skybox2/universe_bottom.png",
            "engine/stock/cubemaps/skybox2/universe_back.png",
            "engine/stock/cubemaps/skybox2/universe_front.png",
            ]
        ),
        game.screen.fb
    );

    //-------------------------------------------------------------------------

    void draw()
    {
        scene.draw();
        skybox.draw(scene.cam.mView(), scene.cam.mProjection());
        /*
        ship.draw(player.cam);
        starfield.draw(player.cam);
        hud.draw();
        */
    }

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,             // FPS (request)
        &draw,          // draw
        scene.actors,   // list of actors

        (SDL_Event *event) {
            switch(event.type)
            {
                case SDL_KEYDOWN: switch(event.key.keysym.sym)
                {
                    //case SDLK_w: ship.shader.fill = !ship.shader.fill; break;
                    //case SDLK_e: ship.shader.enabled = !ship.shader.enabled; break;
                    default: break;
                } break;
                default: break;
            }
            return true;
        }
    );
}

