//*****************************************************************************
//
// Simple object viewer
//
//*****************************************************************************

import engine;

//-----------------------------------------------------------------------------
// We desperately need to give game programmers full control over creating
// GPU side VBOs from loaded data. Let's try to sketch how this is done.
//-----------------------------------------------------------------------------

class GPUMesh
{
    engine.gpu.VAO vao;     // Vertex attribute bindings
    engine.gpu.IBO ibo;     // Draw indexing
    
    this(engine.gpu.Shader.Family family, engine.asset.SceneGraph.Mesh mesh)
    {
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

        ibo = new engine.gpu.IBO(
            cast(ushort[])mesh.triangles,
            GL_TRIANGLES
        );

        //-------------------------------------------------------------------------
        // Create VAO to bind buffers together (automatize buffer bindings)
        //-------------------------------------------------------------------------

        vao = new engine.gpu.VAO();

        vao.bind();
        foreach(attrib; family.attributes.keys()) {
            auto vbo = vbos[attrib];
            family.attrib(attrib, vbo.type, vbo);
        }
        ibo.bind();
        vao.unbind();
        ibo.unbind();
    }

    void draw()
    {
        vao.bind();
        ibo.draw();
        vao.unbind();
    }
}

//-----------------------------------------------------------------------------

import std.random;

import engine.gpu.util;

void main()
{
    game.init(800, 600);

    //vfs.fallback = true;

    //*************************************************************************
    // Before loading models, we create at least one shader to be able to
    // upload buffers to GPU.
    //*************************************************************************

    // Initialize GPU state
    with(gpu.State)
    {
        init(GL_FRONT, GL_CCW);
        init(GL_FRONT_AND_BACK, GL_FILL);
        init(GL_CULL_FACE_MODE, GL_BACK);
        init(GL_BLEND, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        init(GL_BLEND, GL_TRUE);
        init(GL_DEPTH_FUNC, GL_LESS);
        init(GL_DEPTH_TEST);
    }

    // Create shader and bind it to a state
    auto shader = new gpu.Shader(
        vfs.text("data/simpleTBN.glsl")
        //vfs.text("data/simpleN.glsl")
    );

    auto state = new gpu.State(shader)
        //.set(GL_FRONT_AND_BACK, GL_LINE)
    ;

    // Create another shader to display normals using the same "family"
    // attribute bindings) as the main shader.
    
    auto shader_normals = new gpu.Shader(
        shader.family,
        vfs.text("data/normals_vert.glsl"),
        vfs.text("data/normals_vert.glsl"),
        vfs.text("data/normals_vert.glsl")
    );

    auto state_normals = new gpu.State(shader_normals);

    //*************************************************************************
    // Model loading
    //*************************************************************************

    //-------------------------------------------------------------------------
    // Configure asset loader
    //-------------------------------------------------------------------------

    //-------------------------------------------------------------------------
    // Load asset
    //-------------------------------------------------------------------------

    auto scene =
        engine.asset.SceneGraph.load("../../engine/stock/generic/mesh/Suzanne/Suzanne.obj")
        //engine.asset.SceneGraph.load("../../engine/stock/generic/mesh/Cube/Cube.dae")
        //engine.asset.SceneGraph.load("../../engine/stock/generic/mesh/Chess/king.obj")
        //engine.asset.SceneGraph.load("data/Girl/Girl.dae")
        ;

    scene.info();

    //-------------------------------------------------------------------------
    // Post-Load Processing
    //-------------------------------------------------------------------------

    auto mesh = scene.meshes[0];

    mesh.WHD(["X", "Z", "Y"], ["X", "Y", "Z"]);
    //mesh.WHD(["X", "Z", "Y"], ["X", "Z", "Y"]);

    // View mesh info
    {
        auto aabb = mesh.AABB();
        Log << format("AABB: %s - %s", to!string(aabb.min), to!string(aabb.max));
    }

    // Scale mesh to unit size
    {
        auto dim = mesh.dim();
        mesh.scale( 1 / dim.z);
    }

    // Move mesh reference to correct position
    {
        auto aabb = mesh.AABB();
        mesh.move(0, 0, -aabb.min.z);
    }

    // Check results
    {
        auto aabb = mesh.AABB();
        Log << format("AABB: %s - %s", to!string(aabb.min), to!string(aabb.max));
    }

    // Upload model to GPU
    auto gpumesh = new GPUMesh(state.shader.family, mesh);

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
    // After loading is done, it might be a good idea to run GC, because
    // loading can cause massive amounts of temporary objects.
    //-------------------------------------------------------------------------

    engine.Track.GC.run();

    //*************************************************************************
    // Draw settings
    //*************************************************************************

    auto mProjection = mat4.perspective(
        game.screen.width, game.screen.height,
        60,
        1, 200
    );

    auto mView = mat4.look_at(vec3(0, -2, 0.5), vec3(0, 0, 0.5), vec3(0, 0, 1));
    auto pLight = vec3(2, 2, 2);
    
    //*************************************************************************
    // Drawing
    //*************************************************************************

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

        gpumesh.draw();
        
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
        
        gpumesh.draw();
        /**/
    }

    //*************************************************************************
    // Enable profiling and frequent update
    //*************************************************************************

    game.Profile.enable();

    void report()
    {
        game.Profile.log("Perf");
        engine.Track.report("Track");

        Watch("Mem").update("GC heap", to!string(engine.Track.GC.heapsize()));
        Watch("Mem").update("- Used", to!string(engine.Track.GC.heapused()));
        Watch("Mem").update("- Free", to!string(engine.Track.GC.heapfree()));

        game.frametimer.add(0.5, &report);
    }

    report();
    
    //*************************************************************************
    // Game loop
    //*************************************************************************

    simple.gameloop(
        50,     // FPS (limit)
        &draw,  // Drawing
        null,   // list of actors
        null    // Event processing
    );
}

