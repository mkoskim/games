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

void main()
{
    game.init(800, 600);

    vfs.fallback = true;

    //-------------------------------------------------------------------------
    // Load asset
    //-------------------------------------------------------------------------

    auto scene =
        engine.asset.SceneGraph.load("engine/stock/generic/mesh/Suzanne/Suzanne.obj")
        //engine.asset.SceneGraph.load("engine/stock/generic/mesh/Cube/Cube.dae")
        //engine.asset.SceneGraph.load("engine/stock/generic/mesh/Chess/king.obj")
        //engine.asset.SceneGraph.load("data/Girl/Girl.dae")
        //engine.asset.SceneGraph.load("local/stockset/Humanoid/Female/Female.dae")
        //engine.asset.SceneGraph.load("local/stockset/Humanoid/Female/Female.blend")
        ;

    auto mesh = scene.meshes[0];

    //-------------------------------------------------------------------------
    // Textures are uploaded by loaders: these may have different sampling
    // parameters.
    //-------------------------------------------------------------------------

    auto cm_loader = engine.gpu.Texture.Loader.Compressed;
    auto nm_loader = engine.gpu.Texture.Loader.Default;

    auto colormap =
        cm_loader(vec4(0.5, 0.5, 0.5, 1))
        //cm_loader("engine/stock/generic/tiles/AlienCarving/ColorMap.png")
        //cm_loader("engine/stock/generic/tiles/BrickWall1/ColorMap.png")
        //cm_loader("data/Girl/Girl_cm.png")
        //.info()
        ;

    auto normalmap =
        nm_loader(vec4(0.5, 0.5, 1, 0))
        //nm_loader("engine/stock/generic/tiles/AlienCarving/NormalMap.png")
        //nm_loader("engine/stock/generic/tiles/Concrete/Crusty/NormalMap.png")
        //nm_loader("local/stockset/Humanoid/Female/NormalMap.png")
    ;

    //-------------------------------------------------------------------------

    auto mProjection = mat4.perspective(
        game.screen.width, game.screen.height,
        60,
        1, 200
    );

    auto mView = mat4.look_at(vec3(0, -20, 15), vec3(0, 0, 7), vec3(0, 0, 1));
    auto pLight = vec3(5, 3, 7);
    
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
        vfs.text("data/simpleTBN.glsl")
        //vfs.text("data/simpleN.glsl")
    );

    auto state = new gpu.State(shader)
        //.set(GL_FRONT_AND_BACK, GL_LINE)
    ;

    auto shader_normals = new gpu.Shader(
        shader.family,
        vfs.text("data/normals_vert.glsl"),
        vfs.text("data/normals_vert.glsl"),
        vfs.text("data/normals_vert.glsl")
    );

    auto state_normals = new gpu.State(shader_normals);

    auto family = state.shader.family;

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

    game.Profile.enable();

    void report()
    {
        game.Profile.log("Perf");
        
        game.frametimer.add(0.5, &report);
    }

    report();
    
    //-------------------------------------------------------------------------

    simple.gameloop(
        50,     // FPS (limit)
        &draw,  // Drawing
        null,   // list of actors
        null    // Event processing
    );
}

