//*****************************************************************************
//
// Simple object viewer
//
//*****************************************************************************

import engine;

//-----------------------------------------------------------------------------

import std.random;
import std.stdio;

//-----------------------------------------------------------------------------

void main()
{
    //-------------------------------------------------------------------------
    // Init game with default window size
    //-------------------------------------------------------------------------

    game.init();

    //-------------------------------------------------------------------------
    // We need to set up our pipeline. At minimum, this needs one shader
    // batch and one node source.
    //-------------------------------------------------------------------------

    auto pipeline = new scene3d.Pipeline;

    auto shaders = pipeline.shaders;
    auto states = pipeline.states;
    auto batches = pipeline.batches;
        
    shaders.add("default", scene3d.Shader.Default3D());
    states.add("default", scene3d.State.Solid3D(shaders("default")));
    batches.add("default", states("default"));

    //-------------------------------------------------------------------------
    // We need to create a model by uploading it with batch (which we want
    // to use to render the model). We can use asset sets to help this, but
    // it is not mandatory. This demonstrates using asset loader to create
    // renderable models.
    //-------------------------------------------------------------------------

    /* Create asset set named "models" */
    auto asset = pipeline.assets.add("models");
    auto material = pipeline.assets.material;

    /* Load one material */
    asset.upload("material", material(
        //"engine/stock/tiles/Concrete/Dirty/ColorMap.png",
        vec4(1, 0.8, 0, 1)
        //"engine/stock/tiles/Concrete/Dirty/NormalMap.png",
        //0.75
        ));

    /* Load one model */
    asset.upload(
        "model",
        batches("default"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Cube/CubeWrap.obj")
        //blob.wavefront.loadmesh("engine/stock/mesh/Suzanne/Suzanne.obj"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Chess/bishop.obj"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Chess/king.obj"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Chess/knight.obj"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Chess/pawn.obj"),
        //blob.wavefront.loadmesh("engine/stock/mesh/Chess/queen.obj"),
        blob.wavefront.loadmesh("engine/stock/unsorted/mesh/Chess/rook.obj"),
        "material"
    );

    //-------------------------------------------------------------------------
    // Create one node group. Node combines model with position.
    //-------------------------------------------------------------------------

    auto group = pipeline.nodes.add("objects");

    auto object = group.add(scene3d.Grip.movable, asset("model"));

    //object.grip.pos -= model.vao.bsp.center;

    //-------------------------------------------------------------------------
    // Camera! Lights! Action!
    //-------------------------------------------------------------------------

    pipeline.cam = scene3d.Camera.basic3D(
        0.1, 10,        // Near - far
        scene3d.Grip.movable(0, 0, 5)
    );

    pipeline.light = new scene3d.Light(
        scene3d.Grip.fixed(2, 2, 0),    // Position
        vec3(1, 1, 1),                  // Color
        7.5,                            // Range
        0.25                            // Ambient level
    );

    //-------------------------------------------------------------------------
    // Control
    //-------------------------------------------------------------------------

    pipeline.actors.addcallback(() {
        const float moverate = 0.25;
        const float turnrate = 5;

        object.grip.pos += vec3(
            game.controller.axes[game.JOY.AXIS.LX],
            0,
            -game.controller.axes[game.JOY.AXIS.LY]
        ) * moverate;

        object.grip.rot += vec3(
            game.controller.axes[game.JOY.AXIS.RY],
            game.controller.axes[game.JOY.AXIS.RX],
            0
        ) * turnrate;
    });

    //-------------------------------------------------------------------------

    pipeline.actors.reportperf();

    //-------------------------------------------------------------------------

    bool processevents(SDL_Event event)
    {
        switch(event.type)
        {
            default: break;
            case SDL_KEYDOWN: switch(event.key.keysym.sym)
            {
                default: break;
                //case SDLK_w: scene.shader.fill = !scene.shader.fill; break;
                //case SDLK_e: scene.shader.enabled = !scene.shader.enabled; break;
                /*
                case SDLK_r: {
                    static bool normmaps = true;
                    normmaps = !normmaps;
                    maze.shader.activate();
                    maze.shader.uniform("useNormalMapping", normmaps);
                } break;
                */
            }
        }
        return true;
    }

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,             // FPS (limit)
        &pipeline.draw,    // Drawing
        pipeline.actors,   // list of actors
        &processevents
    );
}

