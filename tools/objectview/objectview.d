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
    game.init(800, 600);

    //-------------------------------------------------------------------------
    // Create shader from GLSL, and GPU/OpenGL "state" for the shader: it is
    // intended that these two are tightly coupled - state settings are
    // treated like shader parameters.
    //-------------------------------------------------------------------------

    with(gpu.State)
    {
        init(GL_FRONT_AND_BACK, GL_FILL);
        init(GL_CULL_FACE_MODE, GL_BACK);
        init(GL_FRONT, GL_CCW);
        init(GL_BLEND, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        init(GL_BLEND, GL_TRUE);
        init(GL_DEPTH_FUNC, GL_LESS);
        init(GL_DEPTH_TEST);
    }

    auto shader = new gpu.Shader(
        engine.asset.blob.text("data/simpleTBN.glsl")
        //engine.asset.blob.text("data/simpleN.glsl")
    );

    auto state = new gpu.State(shader)
        //.set(GL_FRONT_AND_BACK, GL_LINE)
    ;

    auto shader_normals = new gpu.Shader(
        shader.family,
        engine.asset.blob.text("data/normals_vert.glsl"),
        engine.asset.blob.text("data/normals_vert.glsl"),
        engine.asset.blob.text("data/normals_vert.glsl")
    );

    auto state_normals = new gpu.State(shader_normals);

    auto family = state.shader.family;

    //-------------------------------------------------------------------------
    // Load asset
    //-------------------------------------------------------------------------

    auto scene =
        //engine.asset.SceneGraph.load("engine/stock/unsorted/mesh/Suzanne/Suzanne.obj")
        //engine.asset.SceneGraph.load("engine/stock/unsorted/mesh/Cube/Cube.dae")
        //engine.asset.SceneGraph.load("engine/stock/unsorted/mesh/Chess/king.obj")
        //engine.asset.SceneGraph.load("data/Girl/Girl.dae")
        engine.asset.SceneGraph.load("engine/stock/unsorted/tests/furnace.dae")
        ;

    auto mesh = scene.meshes[0];

    //-------------------------------------------------------------------------
    // Textures are uploaded by loaders: these may have different sampling
    // parameters.
    //-------------------------------------------------------------------------

    auto cm_loader = engine.gpu.Texture.Loader.Compressed;
    auto nm_loader = engine.gpu.Texture.Loader.Default;

    auto colormap =
        //cm_loader(vec4(0.5, 0.5, 0.5, 1))
        //cm_loader("engine/stock/unsorted/tiles/AlienCarving/ColorMap.png")
        //cm_loader("engine/stock/unsorted/tiles/BrickWall1/ColorMap.png")
        cm_loader("data/Girl/Girl_cm.png")
        ;
    colormap.info();

    auto normalmap =
        nm_loader(vec4(0.5, 0.5, 1, 0))
        //nm_loader("engine/stock/unsorted/tiles/AlienCarving/NormalMap.png")
        //nm_loader("engine/stock/unsorted/tiles/Concrete/Crusty/NormalMap.png")
    ;

    //-------------------------------------------------------------------------
    // Make it GPU VBOs (Vertex Buffer Object) and IBO (vertex indexing array)
    // Here we could use some kind of magic: we can extract shader uniforms
    // and vertex attributes, and then bind them to VBOs with same names.
    //-------------------------------------------------------------------------

    engine.gpu.VBO[string] vbos = [
        "vert_pos": new engine.gpu.VBO(mesh.pos),
        "vert_uv": new engine.gpu.VBO(mesh.uv),
        "vert_T": new engine.gpu.VBO(mesh.t),
        //"vert_B": new engine.gpu.VBO(mesh.b),
        "vert_N": new engine.gpu.VBO(mesh.n),
    ];

    auto ibo = new engine.gpu.IBO(mesh.triangles, GL_TRIANGLES);

    //-------------------------------------------------------------------------
    // Create VAO to bind buffers together (automatize buffer bindings)
    //-------------------------------------------------------------------------

    auto vao = new engine.gpu.VAO();

    vao.bind();
    foreach(attrib; family.attributes.keys()) {
        auto vbo = vbos[attrib];
        family.attrib(attrib, vbo.type, vbo);
    }
    ibo.bind();
    vao.unbind();
    ibo.unbind();

    //-------------------------------------------------------------------------

    auto mProjection = mat4.perspective(
        game.screen.width, game.screen.height,
        60,
        1, 200
    );

    auto mView = mat4.look_at(vec3(0, -3, 2), vec3(0, 0, 2), vec3(0, 0, 1));
    auto pLight = vec3(5, 3, 7);
    
    //-------------------------------------------------------------------------

    void draw()
    {

        static float angle = 0;
        angle += 0.005;

        mat4 mModel = mat4.identity().rotate(angle, vec3(0, 0, 1));

        state.activate();
        with(state.shader)
        {
            uniform("mProjection", mProjection);
            uniform("mView", mView);
            uniform("mModel", mModel);
            uniform("material.colormap", colormap, 0);
            uniform("material.normalmap", normalmap, 1);
            uniform("light.pos", pLight);
        }

        vao.bind();
        ibo.draw();
        vao.unbind();
        
        /*
        state_normals.activate();
        with(state_normals.shader)
        {
            uniform("mProjection", mProjection);
            uniform("mView", mView);
            uniform("mModel", mModel);
            uniform("normal.length", 0.1);
            uniform("normal.color", vec4(0, 0.3, 0, 1));
        }
        
        vao.bind();
        ibo.draw();
        vao.unbind();
        /**/
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

