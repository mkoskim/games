//*****************************************************************************
//*****************************************************************************
//
// (Forthcoming) development of navigation mesh, later added to wolfish/
// project. This is aimed to be used in pseudo-3D games: mesh explicitely
// defines where the object can move and where it can't.
//
// For this, we might want to create CPU side meshes... That is, restructure
// current mesh management first (not all meshes are aimed for rendering).
//
//*****************************************************************************
//*****************************************************************************

import engine;

void main()
{
    //-------------------------------------------------------------------------
    
    game.init();

    auto pipeline = new scene3d.SimplePipeline();

    with(pipeline)
    {
        cam = scene3d.Camera.basic3D(
            0.1, 10,                        // Near - far
            scene3d.Grip.movable(0, 2, 5)   // Position
        );

        light = new scene3d.Light(
            scene3d.Grip.fixed(2, 2, 0),    // Position
            vec3(1, 1, 1),                  // Color
            7.5,                            // Range
            0.25                            // Ambient level
        );

    }

    //-------------------------------------------------------------------------
    // Create navmesh. Create object. Make object moving along navmesh.
    //-------------------------------------------------------------------------

    render.Mesh navmesh;

    navmesh = blob.wavefront.loadmesh("engine/stock/unsorted/mesh/Geom/RectXZ.obj");

    auto nav = pipeline.add(
        scene3d.Grip.fixed(0, -1, 0),
        navmesh,
        pipeline.material(vec4(0.5, 0.5, 0.5, 1))
    );

    auto object = pipeline.add(
        scene3d.Grip.movable(nav.transform), 
        blob.wavefront.loadmesh("engine/stock/unsorted/mesh/Chess/knight.obj"),
        //blob.wavefront.loadmesh("engine/stock/unsorted/mesh/Geom/RectXZ.obj"),
        pipeline.material(vec4(0.8, 0.7, 0.1, 1))
    );

    pipeline.cam.transform.parent = object.transform;

    //-------------------------------------------------------------------------
    // Control
    //-------------------------------------------------------------------------

    pipeline.actors.addcallback(() {
        const float moverate = 0.25;
        const float turnrate = 5;
        
        object.grip.pos += vec3(
            game.controller.axes[game.JOY.AXIS.LX],
            0,
            game.controller.axes[game.JOY.AXIS.LY]
        ) * moverate;
        
        with(pipeline.cam.grip)
        {
            rot += vec3(
                game.controller.axes[game.JOY.AXIS.RY],
                game.controller.axes[game.JOY.AXIS.RX],
                0
            ) * turnrate;
            rot.x = clamp(rot.x, -30, 30);
            rot.y = clamp(rot.y, -30, 30);
        }
    });

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,                 // FPS (limit)
        &pipeline.draw,     // Drawing
        pipeline.actors,    // list of actors
        null
    );

}

