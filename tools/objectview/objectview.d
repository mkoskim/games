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
            cast(ushort[])mesh.faces,
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

    engine.asset.SceneGraph.gWHD = engine.asset.SceneGraph.WHD("X", "Z", "Y");

    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------

    class Model
    {
        GPUMesh mesh;
        engine.gpu.Texture colormap;
        engine.gpu.Texture normalmap;
        
        this(
            engine.gpu.Shader.Family family,
            string filename, string[3] WHD, engine.asset.Option[] options,
            engine.gpu.Texture colormap,
            engine.gpu.Texture normalmap,
            vec3 saxis, float scale, vec3 refpoint)
        {
            auto mesh = engine.asset.loadmesh(filename, WHD, options);
            mesh.postprocess(saxis, scale, refpoint);
            this.mesh = new GPUMesh(family, mesh);
            this.colormap = colormap;
            this.normalmap = normalmap;
        }
    }

    //-------------------------------------------------------------------------
    // Load asset
    //-------------------------------------------------------------------------

    static if(0) auto model = new Model(
        state.shader.family,
        "data/Girl/Girl.dae", ["X", "Z", "-Y"], [engine.asset.Option.FlipUV],
        engine.asset.loadcolormap("data/Girl/Girl_cm.png"),
        engine.asset.loadnormalmap(vec4(0.5, 0.5, 1, 0)),
        vec3(0, 0, 1), 1.0, vec3(0.5, 0.5, 0.0)
    );

    static if(0) auto model = new Model(
        state.shader.family,
        "../../engine/stock/generic/mesh/Suzanne/Suzanne.obj", ["X", "Y", "Z"], [],
        engine.asset.loadcolormap(vec4(0.5, 0.5, 0.5, 1)),
        engine.asset.loadnormalmap(vec4(0.5, 0.5, 1, 0)),
        vec3(0, 0, 1), 1.0, vec3(0.5, 0.5, 0.0)
    );

    static if(0) auto model = new Model(
        state.shader.family,
        "../../engine/stock/generic/mesh/Chess/king.obj", ["X", "Y", "Z"], [],
        engine.asset.loadcolormap(vec4(0.5, 0.5, 0.5, 1)),
        engine.asset.loadnormalmap(vec4(0.5, 0.5, 1, 0)),
        vec3(0, 0, 1), 1.0, vec3(0.5, 0.5, 0.0)
    );

    static if(1) auto model = new Model(
        state.shader.family,
        "../../engine/stock/generic/mesh/Cube/CubeWrap.obj", ["X", "Y", "Z"], [],
        engine.asset.loadcolormap("../../engine/stock/generic/tiles/BrickWall1/ColorMap.png"),
        engine.asset.loadnormalmap("../../engine/stock/generic/tiles/BrickWall1/NormalMap.png"),
        vec3(0, 0, 1), 1.0, vec3(0.5, 0.5, 0.0)
    );

    static if(0) auto model = new Model(
        state.shader.family,
        "../../engine/stock/generic/mesh/Cube/CubeWrap.obj", ["X", "Y", "Z"], [],
        engine.asset.loadcolormap("../../engine/stock/generic/tiles/AlienCarving/ColorMap.png"),
        engine.asset.loadnormalmap("../../engine/stock/generic/tiles/AlienCarving/NormalMap.png"),
        vec3(0, 0, 1), 1.0, vec3(0.5, 0.5, 0.0)
    );

    static if(0) auto model = new Model(
        state.shader.family,
        "../../engine/stock/generic/mesh/Cube/CubeWrap.obj", ["X", "Y", "Z"], [],
        engine.asset.loadcolormap("../../engine/stock/generic/tiles/Concrete/Crusty/ColorMap.png"),
        engine.asset.loadnormalmap("../../engine/stock/generic/tiles/Concrete/Crusty/NormalMap.png"),
        vec3(0, 0, 1), 1.0, vec3(0.5, 0.5, 0.0)
    );

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
            uniform("light.pos", pLight);
        }

        with(state.shader)
        {
            uniform("mModel", mModel);
            uniform("material.colormap", model.colormap, 0);
            uniform("material.normalmap", model.normalmap, 1);
        }
        model.mesh.draw();
        
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
        engine.Track.GC.report("Mem");

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

