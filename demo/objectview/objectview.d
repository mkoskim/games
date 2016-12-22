//*****************************************************************************
//
// Simple object viewer
//
//*****************************************************************************

import engine;

//-----------------------------------------------------------------------------

import std.random;
import std.stdio;

import engine.gpu.util;

//*****************************************************************************
//
static if(1)
//
//*****************************************************************************

void main()
{
    game.init();

    //-------------------------------------------------------------------------

    auto shader = new gpu.Shader(
        engine.asset.blob.text("data/simple.glsl")
    );

    auto state = new gpu.State(
        shader,
        (){
            checkgl!glEnable(GL_CULL_FACE);
            checkgl!glCullFace(GL_BACK);
            checkgl!glFrontFace(GL_CCW);
            checkgl!glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            //checkgl!glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
            checkgl!glEnable(GL_DEPTH_TEST);
            checkgl!glDisable(GL_BLEND);
        }
    );
    
    //-------------------------------------------------------------------------

    //auto scene = engine.asset.SceneGraph.load("data/test.dae");
    auto scene = engine.asset.SceneGraph.load("engine/stock/unsorted/mesh/Cube/Cube.obj");

    auto mesh = scene.meshes[0];

    engine.gpu.VBO[string] vbos = [
        "vert_pos": new engine.gpu.VBO("vert_pos", mesh.pos),
        "vert_uv": new engine.gpu.VBO("vert_uv",  mesh.uv),
        "vert_T": new engine.gpu.VBO("vert_T",  mesh.t),
        "vert_B": new engine.gpu.VBO("vert_B",  mesh.b),
        "vert_N": new engine.gpu.VBO("vert_N",  mesh.n),
    ];

    auto ibo = new engine.gpu.IBO(mesh.triangles, GL_TRIANGLES);

    //-------------------------------------------------------------------------

    auto vao = new engine.gpu.VAO();
    
    vao.bind();
    foreach(attrib; shader.attributes.keys()) {
        auto vbo = vbos[attrib];
        shader.attrib(attrib, vbo.type, vbo);
    }
    ibo.bind();
    vao.unbind();
    ibo.unbind();

    //-------------------------------------------------------------------------

    auto loader   = engine.gpu.Texture.Loader.Default;
    auto colormap = 
        loader(vec4(0.5, 0.5, 0.5, 1))
        //loader("engine/stock/unsorted/tiles/AlienCarving/ColorMap.png")
        ;
    auto normalmap = 
        //loader(vec4(0.5, 0.5, 1, 0))
        loader("engine/stock/unsorted/tiles/AlienCarving/NormalMap.png")
    ;

    //-------------------------------------------------------------------------

    auto mProjection = mat4.perspective(
        game.screen.width, game.screen.height,
        60,
        1, 100
    );

    auto mView = mat4.identity().translate(0, 0, -5);

    auto pLight = vec3(5, 5, 0);

    //-------------------------------------------------------------------------

    void draw()
    {
        state.activate();
        
        state.shader.uniform("mProjection", mProjection);
        state.shader.uniform("mView", mView);
        state.shader.uniform("material.colormap", colormap, 0);
        state.shader.uniform("material.normalmap", normalmap, 1);
        state.shader.uniform("light.pos", pLight);
    
        static float angle = 0;
        state.shader.uniform("mModel", mat4.identity().rotate(angle, vec3(1, 1, 0)));
        angle += 0.01;

        vao.bind();
        ibo.draw();
        vao.unbind();
    }
    
    //-------------------------------------------------------------------------

    simple.gameloop(
        50,     // FPS (limit)
        &draw,  // Drawing
        null,   // list of actors
        null    // Event processing
    );
}

//*****************************************************************************
//
else 
//
//*****************************************************************************

void main()
{
    //-------------------------------------------------------------------------
    // Init game with default window size
    //-------------------------------------------------------------------------

    game.init();

    auto pipeline = new scene3d.SimplePipeline();

    with(pipeline)
    {
        cam = scene3d.Camera.basic3D(
            0.1, 10,        // Near - far
            scene3d.Grip.movable(0, 0, 5)
        );

        light = new scene3d.Light(
            scene3d.Grip.fixed(2, 2, 0),    // Position
            vec3(1, 1, 1),                  // Color
            7.5,                            // Range
            0.25                            // Ambient level
        );
    }

    auto scene = engine.asset.SceneGraph.load("data/test.dae");
    auto node = scene.lookup["Cube"];

/*
    auto node = pipeline.add(
        scene3d.Grip.movable, 
            //blob.wavefront.loadmesh("engine/stock/mesh/Cube/CubeWrap.obj")
            //blob.wavefront.loadmesh("engine/stock/mesh/Suzanne/Suzanne.obj"),
            //blob.wavefront.loadmesh("engine/stock/mesh/Chess/bishop.obj"),
            //blob.wavefront.loadmesh("engine/stock/mesh/Chess/king.obj"),
            //blob.wavefront.loadmesh("engine/stock/mesh/Chess/knight.obj"),
            //blob.wavefront.loadmesh("engine/stock/mesh/Chess/pawn.obj"),
            //blob.wavefront.loadmesh("engine/stock/mesh/Chess/queen.obj"),
            blob.wavefront.loadmesh("engine/stock/unsorted/mesh/Chess/rook.obj"),
        pipeline.material(
            //"engine/stock/tiles/Concrete/Dirty/ColorMap.png",
            vec4(1, 0.8, 0, 1)
            //"engine/stock/tiles/Concrete/Dirty/NormalMap.png",
            //0.75
        )
    );
*/

    //-------------------------------------------------------------------------
    // Control
    //-------------------------------------------------------------------------

    pipeline.actors.addcallback(() {
        const float moverate = 0.25;
        const float turnrate = 5;

        node.grip.pos += vec3(
            game.controller.axes[game.JOY.AXIS.LX],
            0,
            -game.controller.axes[game.JOY.AXIS.LY]
        ) * moverate;

        node.grip.rot += vec3(
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

