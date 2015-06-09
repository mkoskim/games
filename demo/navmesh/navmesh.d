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

//-----------------------------------------------------------------------------
// Maze is represented by triangles, which have base point and two vectors
// defining the plane.
//-----------------------------------------------------------------------------

class NavFace
{
    vec3 basepoint;         // World coordinates
    vec3 a, b;              // Sides

    NavFace*[3] edges;  // Where edges lead
}

//-----------------------------------------------------------------------------
// Agents represent objects that are tied to navmesh. They have reference
// to the current triangle they are located, and local coordinates to it
// (including height).
//
// TODO: This could be implemented sort of a "grip", that is, transformation
// is fetched from navigation mesh.
//
//-----------------------------------------------------------------------------

class NavAgent
{
    NavNode base;
    vec3 local;
}

//-----------------------------------------------------------------------------

void main()
{
    //-------------------------------------------------------------------------
    
    game.init();

    //-------------------------------------------------------------------------
    // Scene! Lights! Camera!
    //-------------------------------------------------------------------------
        
    auto cam = render.Camera.basic3D(
        0.1, 10,        // Near - far
        render.Grip.movable(0, 0, 5)
    );

    auto scene = new render.DirectRender(
        cam,
        render.State.Solid3D()
    );

    scene.light = new render.Light(
        render.Grip.fixed(2, 2, 0), // Position
        vec3(1, 1, 1),              // Color
        7.5,                        // Range
        0.25                        // Ambient level
    );

    //-------------------------------------------------------------------------

    auto nodes = scene.addbatch();

    auto model = nodes.upload(
        blob.wavefront.loadmesh("engine/stock/mesh/Chess/knight.obj"),
        vec4(0.8, 0.7, 0.1, 1)
    );

    auto object = scene.add(render.Grip.movable, model);

    //-------------------------------------------------------------------------
    // Control
    //-------------------------------------------------------------------------

    auto actors = new game.FiberQueue();
    auto joystick = game.joysticks[0];

    actors.addcallback(() {
        const float moverate = 0.25;
        const float turnrate = 5;
        
        object.grip.pos += vec3(
            joystick.axes[game.JOY.AXIS.LX],
            0,
            -joystick.axes[game.JOY.AXIS.LY]
        ) * moverate;
        
        object.grip.rot += vec3(
            joystick.axes[game.JOY.AXIS.RY],
            joystick.axes[game.JOY.AXIS.RX],
            0
        ) * turnrate;
    });

    //-------------------------------------------------------------------------

    simple.gameloop(
        50,             // FPS (limit)
        &scene.draw,    // Drawing
        actors,         // list of actors
        null
    );

}

