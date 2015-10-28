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
// Create render pipeline batches:
//
//      solid        Light'd render for most objects
//      flat         Unlight'd render for stars (in star field)
//
//*****************************************************************************

scene3d.Pipeline createPipeline()
{
    auto pipeline = new scene3d.Pipeline();

    auto shaders = pipeline.shaders;
    auto states = pipeline.states;
    auto batches = pipeline.batches;
    
    states.Solid3D("default", shaders.Default3D("default"));
    states.Solid3D("flat", shaders.Flat3D("flat"));
    
    batches.add("solid", states("default"));
    batches.add("flat", states("flat"));

    return pipeline;
}

//*****************************************************************************
//
// Create game assets
//
//*****************************************************************************

void loadModels(scene3d.Pipeline pipeline)
{
    //---------------------------------------------------------------------
    // Create asset sets
    //---------------------------------------------------------------------

    auto player = pipeline.assets.add("player");
    auto mothership = pipeline.assets.add("mothership");
    auto starfield = pipeline.assets.add("starfield");

    //---------------------------------------------------------------------

    auto batches = pipeline.batches;
    auto material = pipeline.assets.material;    

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

    mothership.upload(
        "floor",
        batches("solid"),
        blob.wavefront.loadmesh("data/mesh/Floor.obj").move(0, RADIUS, 0),
        material(vec4(0.5, 0.5, 0.5, 1), 0.85)
    );

    mothership.upload(
        "wall",
        batches("solid"),
        blob.wavefront.loadmesh("data/mesh/Wall.obj").move(0, RADIUS, 0),
        material(warnbmp, 0.75)
    );

    mothership.upload(
        "tower",
        batches("solid"),
        blob.wavefront.loadmesh("data/mesh/Guntower.obj").move(0, RADIUS, 0),
        material(vec4(1, 0, 0, 1), 0.75)
    );

    //---------------------------------------------------------------------

    starfield.upload(
        "star",
        batches("flat"),
        blob.wavefront.loadmesh("engine/stock/unsorted/mesh/Cube/Cube.obj").scale(0.075),
        material(vec4(1, 1, 0.75, 1), 0.75)
    );

    //---------------------------------------------------------------------

    player.upload(
        "ship",
        batches("solid"),
        blob.wavefront.loadmesh("data/mesh/Ship.obj"), //.scale(1.25)
        material(vec4(0.4, 0.4, 0.7, 1))
    );
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

class MotherShip
{
    float length = 0;

    void createStars(scene3d.Pipeline pipeline, int count, float minx, float maxx, float minz, float maxz)
    {
        auto stars = pipeline.nodes.add("stars");
        auto star  = pipeline.assets("starfield")("star");

        foreach(i; 0 .. count)
        {
            float angle = random.uniform(0, 360)*(2*PI/360);
            float dist  = random.uniform(minz, maxz);

            vec3 pos = vec3(
                random.uniform(minx, maxx),
                dist*cos(angle),
                dist*sin(angle)
            );
            stars.add(pos, star);
        }
    }

    this(scene3d.Pipeline pipeline, string[] grid)
    {
        auto nodes  = pipeline.nodes.add("mothership");
        auto towers = pipeline.nodes.add("mothership.towers");
        auto models = pipeline.assets("mothership");
        
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
                    case 'X': nodes.add(grip, models("floor")); break;
                    case '#': nodes.add(grip, models("wall")); break;
                    case 'O': towers.add(grip, models("tower")); break;

                    case ' ': break;
                    default: throw new Exception("Unknown char: " ~ c);
                }
            }
        }

        createStars(
            pipeline,
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

    float MINX, MAXX;

    //-------------------------------------------------------------------------

    this(scene3d.Pipeline pipeline, MotherShip mothership)
    {
        super(pipeline.actors);

        //---------------------------------------------------------------------

        auto nodes = pipeline.nodes.add("player");
        auto playership = pipeline.assets("player")("ship");

        //---------------------------------------------------------------------

        MINX = -10;
        MAXX = mothership.length + 10;

        //---------------------------------------------------------------------

        root = scene3d.Grip.movable(-40, 0, 0);
        shipframe = scene3d.Grip.movable(root, vec3(0, RADIUS + 0.4, 0));

        ship = nodes.add(scene3d.Grip.movable(shipframe), playership);

        // Make ship rolling when coming in
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
        
        pipeline.cam = cam;

        pipeline.light = new scene3d.Light(
            scene3d.Grip.fixed(0, 10, 0),
            vec3(1, 1, 1),
            40,
            0.2
        );
    }

    //-------------------------------------------------------------------------
    //
    // We use translation to achieve stable transitions. Camera position,
    // ship velocity and orientation are controlled by speed, which is
    // (mainly) controlled by joystick.
    //
    //-------------------------------------------------------------------------
    
    override void run()
    {
        //---------------------------------------------------------------------
        // Moving, with turn control
        //---------------------------------------------------------------------
        
        auto rotation = new Translate(vec2(-1, -2.5), vec2(+1, +2.5));

        const float MAXSPEED  = 30;
        const float TURNSTART = 10;
        const float DELTA     =  1;
        
        auto velocity   = new Translate(vec2(-MAXSPEED, -0.5), vec2(+MAXSPEED,  +0.5));
        auto campos     = new Translate(vec2(-MAXSPEED, -5.0), vec2(+MAXSPEED,  +5.0));
        auto camposturn = new Translate(vec2(-TURNSTART,-5.0), vec2(+TURNSTART, +5.0));

        auto shiprotz   = new Translate(vec2(-TURNSTART,-180), vec2(+TURNSTART, 0));

        float speed = MAXSPEED * 0.5;

        void update()
        {
            root.grip.rot.x += rotation(game.controller.axes[game.JOY.AXIS.LY]);

            shipframe.grip.rot.x =  game.controller.axes[game.JOY.AXIS.LY] * 30;	// "Roll"
            shipframe.grip.rot.z = -game.controller.axes[game.JOY.AXIS.LX] * 45;	// "Pitch"

            root.grip.pos.x += velocity(speed);
            cam.grip.pos.x  = campos(speed) + camposturn(speed);
            ship.grip.rot.z = shiprotz(speed);
        }
        
        //---------------------------------------------------------------------

        for(;;)
        {
            // Zooming for development purposes
            cam.grip.pos.y += game.controller.axes[game.JOY.AXIS.RY] * 0.5;

            /* Auto-turn on edges */
            if(root.grip.pos.x < MINX)
            {
                if(speed < MAXSPEED*0.5) speed++;
            }
            else if(root.grip.pos.x > MAXX)
            {
                if(speed > -MAXSPEED*0.5) speed--;
            }
            else
            {
                float acceleration = game.controller.axes[game.JOY.AXIS.LX] * DELTA;

                speed = fmax(-MAXSPEED, fmin(speed + acceleration, MAXSPEED));
            }

            if(abs(speed) < TURNSTART) {
                float delta = -sgn(speed) * DELTA;
                while(abs(speed) < TURNSTART)
                {
                    speed += delta;
                    update();
                    nextframe();
                }
                continue;
            }

            /* In case our ship is upside down, turn it back */
            if(ship.grip.rot.x < ship.grip.rot.z) ship.grip.rot.x += min(8, ship.grip.rot.z - ship.grip.rot.x);
            if(ship.grip.rot.x > ship.grip.rot.z) ship.grip.rot.x -= min(8, ship.grip.rot.x - ship.grip.rot.z);

            update();
            nextframe();
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

    auto pipeline = createPipeline();

    loadModels(pipeline);

    auto mothership = new MotherShip(pipeline, grid.greeting);
    auto player = new Player(pipeline, mothership);

    pipeline.actors.reportperf;

    //-------------------------------------------------------------------------
    // Things like this, these would be great to be encapsuled as loader
    // scripts written in some scripting language like lua. This particular
    // skybox does not like that good at background, it is just a
    // placeholder.
    //-------------------------------------------------------------------------

    auto skybox = new postprocess.SkyBox(
        new render.Cubemap([
            "engine/stock/unsorted/cubemaps/skybox2/universe_right.png",
            "engine/stock/unsorted/cubemaps/skybox2/universe_left.png",
            "engine/stock/unsorted/cubemaps/skybox2/universe_top.png",
            "engine/stock/unsorted/cubemaps/skybox2/universe_bottom.png",
            "engine/stock/unsorted/cubemaps/skybox2/universe_back.png",
            "engine/stock/unsorted/cubemaps/skybox2/universe_front.png",
            ]
        ),
        game.screen.fb
    );

    //-------------------------------------------------------------------------

    void draw()
    {
        pipeline.draw();
        skybox.draw(pipeline.cam.mView(), pipeline.cam.mProjection());
    }

    //-------------------------------------------------------------------------

    bool processevents(SDL_Event event)
    {
        switch(event.type)
        {
            /*
            case SDL_JOYBUTTONDOWN:
                writefln("Joy(%d) button: %d", event.jbutton.which, event.jbutton.button);
                break;
            */

            case SDL_KEYDOWN: switch(event.key.keysym.sym)
            {
                //case SDLK_w: ship.shader.fill = !ship.shader.fill; break;
                //case SDLK_e: ship.shader.enabled = !ship.shader.enabled; break;

                //case SDLK_ESCAPE: return false;
                default: break;
            } break;
            default: break;
        }
        return true;
    }

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,                 // FPS (request)
        &draw,              // draw
        pipeline.actors,    // list of actors
        &processevents
    );
    //-------------------------------------------------------------------------
}

//*****************************************************************************
//*****************************************************************************
//*****************************************************************************
//*****************************************************************************

    //-------------------------------------------------------------------------
    // HUD (2D graphics not working atm)
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

