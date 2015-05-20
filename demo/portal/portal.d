//*****************************************************************************
//
// Portal demonstration.
//
//*****************************************************************************

import engine;

//*****************************************************************************
//
// Sketching new way to implement rendering.
//
// 1) Applying View to world data to create set of possibly visible
//    objects.
//
// 2) Classifying, sorting and feeding filtered lists to shaders
//
//*****************************************************************************

//-----------------------------------------------------------------------------

import engine.render.layer;
import engine.render.instance;
import engine.render.view;
import engine.render.bone;

class Zone
{
    class Portal
    {
        vec3 p1, p2, p3, p4;
        Bone grip;
    }
    
    InstanceGroup content;
    Portal[] portals;

    this(InstanceGroup content)
    {
        this.content = content;
    }
    
    ~this() { }

    void connect(Zone room, Portal portal)
    {
    }

    void collect(Batch batch, View cam, Portal portal)
    {
        // TODO: Don't add duplicates, if few portals connect to
        // same room!
        foreach(k, v; content.instances)
        {
            batch.add(k);
        }
    }

}

//-----------------------------------------------------------------------------

void main()
{
    //-------------------------------------------------------------------------
    
    game.init();

    auto scene = new render.Scene();

    //-------------------------------------------------------------------------
        
    auto shape = new render.Shape(
        scene.shader.upload(
            //blob.wavefront.loadmesh("engine/stock/mesh/Cube/CubeWrap.obj")
            blob.wavefront.loadmesh("engine/stock/mesh/Suzanne/Suzanne.obj")
        ),
        new render.Material(
            new render.Texture("engine/stock/tiles/CrackedPlaster/ColorMap.png"),
            new render.Texture("engine/stock/tiles/CrackedPlaster/NormalMap.png"),
            0.95
        )
    );

    //-------------------------------------------------------------------------
    
    auto floormesh = scene.shader.upload(
        blob.wavefront.loadmesh("engine/stock/mesh/Cube/Floor.obj")
    );
    
    auto floor = [
        new render.Shape(floormesh, new render.Material(vec4(0.2, 0.2, 0.2, 1))),
        new render.Shape(floormesh, new render.Material(vec4(0.8, 0.8, 0.8, 1)))
    ];

    //-------------------------------------------------------------------------

    auto world = new Zone(new InstanceGroup(scene.shader));
    auto box = new Zone(new InstanceGroup(scene.shader));

    foreach(y; 0 .. 3) foreach(x; 0 .. 3)
    {
        box.content.add(vec3(x*2, 0, -y*2), floor[(x+y) % 2]);
    }

    //-------------------------------------------------------------------------
    // Scene! Lights! Camera!
    //-------------------------------------------------------------------------
        
    scene.light = new render.Light(
        vec3(0, 2, 0),      // Position
        vec3(1, 1, 1),      // Color
        10,                 // Range
        0.1                 // Ambient level
    );

    auto camrot = new render.Bone(null);
    auto campos = new render.Bone(camrot, vec3(0, 0, 5));
    
    auto cam = render.Camera.basic3D(
        0.1, 15,        // Near - far
        campos
    );

    //-------------------------------------------------------------------------
    // Control
    //-------------------------------------------------------------------------

    auto actors = new game.FiberQueue();
    auto joystick = game.joysticks[0];

    actors.addcallback(() {
        const float moverate = 0.25;
        const float turnrate = 5;
        
        campos.pos += vec3(
            joystick.axes[game.JOY.AXIS.LX],
            0,
            -joystick.axes[game.JOY.AXIS.LY]
        ) * moverate;
        
        camrot.rot += vec3(
            -joystick.axes[game.JOY.AXIS.RY],
            joystick.axes[game.JOY.AXIS.RX],
            0
        ) * turnrate;
    });

    //-------------------------------------------------------------------------
    // Sketching new approach to drawing.
    //-------------------------------------------------------------------------
    
    void draw()
    {
        //---------------------------------------------------------------------
        // 1) Create batches from world data
        //---------------------------------------------------------------------
        
        Batch batch = new Batch();

        box.collect(batch, cam, null);

        //---------------------------------------------------------------------
        // 2) Feed batches to shader(s)
        //---------------------------------------------------------------------
        
        scene.shader.activate();
        scene.shader.loadView(cam);

        if(scene.light) scene.shader.light(scene.light);

        batch.draw(scene.shader);
    }

    //-------------------------------------------------------------------------
    // Game loop
    //-------------------------------------------------------------------------

    simple.gameloop(
        50,       // FPS (limit)
        &draw,     // Drawing
        actors,   // list of actors

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
                }
            }
            return true;
        }
    );
}

