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
// Star field: This version creates single instance containing the stars as
// points. This disables frustum culling for single stars, but on the other
// hand it decreases CPU load feeding stars to GPU.
//
//*****************************************************************************

class StarField : render.Scene
{
    this(int count, float minx, float maxx, float minz, float maxz)
    {
        super(render.shaders.Lightless3D.create());

        useFrustumCulling = false;
        useSorting = false;

        auto mesh = new render.Mesh(GL_POINTS);

        foreach(i; 0 .. count)
        {
            float angle = random.uniform(0, 360)*(2*PI/360);
            float dist  = random.uniform(minz, maxz);

            vec3 pos = vec3(
                random.uniform(minx, maxx),
                dist*cos(angle),
                dist*sin(angle)
            );
            mesh.addface(mesh.addvertex(pos));
        }

        add(
            vec3(0, 0, 0),
            shader.upload(mesh),
            new render.Material(0.75, 0.75, 0.75)
        );
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

class MotherShip : render.Scene
{
    float length = 0;

    this(string[] grid)
    {
        //super(render.shaders.Toon.create());
        //super(render.shaders.Blanko.create());
        super();

        //---------------------------------------------------------------------

        light = new render.Light(
            vec3(0, 10, 0),
            vec3(1, 1, 1),
            40,
            0.2
        );

        //-------------------------------------------------------------------------
        // Black-yellow stripes texture
        //-------------------------------------------------------------------------

        auto warnbmp = new Bitmap(32, 32);
        foreach(x; 0 .. warnbmp.width) foreach(y; 0 .. warnbmp.height) {
            warnbmp.putpixel(x, y,
                (((x+y) % 32) < 16) ? vec4(1, 1, 0, 1) : vec4(0, 0, 0, 1)
            );
        }

        //-------------------------------------------------------------------------

        auto normCrustyConcrete = new render.Texture("engine/stock/tiles/Concrete/Crusty/NormalMap.png");
        auto normCrackedPlaster = new render.Texture("engine/stock/tiles/CrackedPlaster/NormalMap.png");
        auto normCaveWall = new render.Texture("engine/stock/tiles/CaveWall/NormalMap.png");
        auto normTanStucco = new render.Texture("engine/stock/tiles/TanStucco/NormalMap.png");
        auto normPaddedWall = new render.Texture("engine/stock/tiles/PaddedWall/NormalMap.png");

        auto normAlienCarving = new render.Texture("engine/stock/tiles/AlienCarving/NormalMap.png");
        auto normSFCafeteria = new render.Texture("engine/stock/tiles/SpaceshipCafeteria/NormalMap.png");

        auto floor = new render.Shape(
            shader.upload(
                blob.wavefront.loadmesh("data/mesh/Floor.obj")
                .move(0, RADIUS, 0)
            ),
            new render.Material(
                vec4(0.5, 0.5, 0.5, 1),
                //normPaddedWall,
                0.85
            )
        );

        auto wall = new render.Shape(
            shader.upload(
                blob.wavefront.loadmesh("data/mesh/Wall.obj")
                .move(0, RADIUS, 0)
            ),
            new render.Material(warnbmp.surface, 0.75)
        );

        auto tower = new render.Shape(
            shader.upload(
                blob.wavefront.loadmesh("data/mesh/Guntower.obj")
                //blob.wavefront.loadmesh("engine/stock/mesh/Suzanne/Suzanne.obj")
                .move(0, RADIUS, 0)
            ),
            new render.Material(vec4(1, 0, 0, 1), 0.75)
        );

        //-------------------------------------------------------------------------

        foreach(y, line; grid)
        {
            foreach(x, c; line)
            {
                vec3 pos = vec3(2*x, 0, 0);
                vec3 rot = vec3(360.0/GRID_H*y, 0, 0);

                length = max(length, pos.x);

                switch(c)
                {
                    case '|':
                    case '-':
                    case 'X': add(pos, floor).grip.rot = rot; break;
                    case '#': add(pos, wall).grip.rot = rot; break;
                    case 'O': add(pos, tower).grip.rot = rot; break;

                    //case ' ': add(pos, floormesh, floormat2).rot = rot; break;
                    case ' ': break;
                    default: throw new Exception("Unknown char: " ~ c);
                }
            }
        }
    }
}

//*****************************************************************************
//
// Player
//
//*****************************************************************************

class Player : game.Fiber
{
    MotherShip mothership;

    render.Bone root, shipframe;
    render.Instance ship;
    render.Camera cam;

    game.Joystick joystick;

    //-------------------------------------------------------------------------

    this(game.FiberQueue queue, MotherShip mothership)
    {
        super(queue);

        //---------------------------------------------------------------------

        this.mothership = mothership;
        joystick = game.joysticks[0];

        //---------------------------------------------------------------------

        root = new render.Bone(null, vec3(-40, 0, 0));
        shipframe = new render.Bone(root, vec3(0, RADIUS + 0.4, 0));

        ship = mothership.add(shipframe, new render.Shape(
            mothership.shader,
            blob.wavefront.loadmesh("data/mesh/Ship.obj"), //.scale(1.25)
            new render.Material(vec4(0.4, 0.4, 0.7, 1))
        ));
        ship.grip.rot.x = 360;

        //---------------------------------------------------------------------

        cam = render.Camera.basic3D(
            CAM_HEIGHT - MAX_HEIGHT, 100,
            new render.Bone(
                root,
                vec3(7.5, CAM_HEIGHT, 0),
                vec3(-90, 0, 0)
            )
        );
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
            root.rot.x += joystick.axes[game.JOY.AXIS.LY] * maxrot;

            shipframe.rot.x =  joystick.axes[game.JOY.AXIS.LY] * 30;	// "Roll"
            shipframe.rot.z = -joystick.axes[game.JOY.AXIS.LX] * 45;	// "Pitch"
        }

        void checkturn()
        {
            if(speed < -0.1 || speed > 0.1) {
                root.pos.x += speed;
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
                root.pos.x += speed;
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

            if(root.pos.x < -10)
            {
                if(speed < maxspeed*0.5) speed += delta;
            }
            else if(root.pos.x > mothership.length + 10)
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
// Some kind of texts that can be put on screen, they fade in, stay for
// a while, and then fade out.
//
//*****************************************************************************

class FadingText
{
}

//*****************************************************************************
//
// Main
//
//*****************************************************************************

void main()
{
    game.init(800, 600);

    auto actors = new game.FiberQueue();

    //-------------------------------------------------------------------------
    // Mother ship and star field
    //-------------------------------------------------------------------------

    auto ship = new MotherShip(grid.greeting);
    auto starfield = new StarField(
        500,
        -50, ship.length + 50,
        MAX_HEIGHT + 0.1, 2*MAX_HEIGHT
    );

    //-------------------------------------------------------------------------
    // Player
    //-------------------------------------------------------------------------

    auto player = new Player(actors, ship);

    //-------------------------------------------------------------------------
    // HUD
    //-------------------------------------------------------------------------

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

    //-------------------------------------------------------------------------

    void draw()
    {
        ship.draw(player.cam);
        starfield.draw(player.cam);
        hud.draw();
    }

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,         // FPS (request)
        &draw,      // draw
        actors,     // list of actors

        (SDL_Event *event) {
            switch(event.type)
            {
                case SDL_KEYDOWN: switch(event.key.keysym.sym)
                {
                    case SDLK_w: ship.shader.fill = !ship.shader.fill; break;
                    case SDLK_e: ship.shader.enabled = !ship.shader.enabled; break;
                    default: break;
                } break;
                default: break;
            }
            return true;
        }
    );
}

