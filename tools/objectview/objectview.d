//*****************************************************************************
//
// Simple object viewer
//
//*****************************************************************************

import engine;

//-----------------------------------------------------------------------------
// Information about objects in files. These should be moved as external
// files, like inside loader Lua scripts.
//-----------------------------------------------------------------------------

struct FileInfo {
    engine.asset.Plane plane;
    engine.asset.Scene.Flag[] flags;

    this(engine.asset.Plane plane, engine.asset.Scene.Flag[] flags)
    {
        this.plane = plane;
        this.flags = flags;
    }
}

FileInfo[string] fileinfo;

static this()
{
    fileinfo["data/Girl/Girl.dae"] = FileInfo(engine.asset.Plane.XYF, [engine.asset.Scene.Flag.FlipUV]);
    fileinfo["../../engine/stock/generic/mesh/Suzanne/Suzanne.obj"] =FileInfo(engine.asset.Plane.XZF, []);
    fileinfo["../../engine/stock/generic/mesh/Cube/Cube.dae"] = FileInfo(engine.asset.Plane.XY, []);
    fileinfo["../../engine/stock/generic/mesh/Cube/CubeWrap.obj"] = FileInfo(engine.asset.Plane.XZ, []);
    fileinfo["../../engine/stock/generic/mesh/Chess/king.obj"] = FileInfo(engine.asset.Plane.XZ, []);
}

//-----------------------------------------------------------------------------
// We desperately need to give game programmers full control over creating
// GPU side VBOs from loaded data. Let's try to sketch how this is done.
// This is basically part of a pipeline: depending on your shader, you might
// want to tweak the bindings, buffers and layouts.
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// We need to simplify setting up simple 3D pipelines. At the same time, we
// need to make sure that you can build your own pipeline for your game when
// you need/want one. Let's sketch it here.
//-----------------------------------------------------------------------------

class Model : engine.asset.Mesh
{
    // First one strange thing: You should notice that you can't free
    // up VBOs after binding them to VAO. CPU-side buffers used to create
    // thse buffers are free to go, but VBOs hold GPU side IDs on them!
    // Now, the following code looks like the VBOs are discarded after VAO
    // creation! Check this! It works, thought...
    
    // We could try to simplify things so, that VBOs and IBOs are created
    // under VAO, which takes care of them. When VAO is released, also the
    // IBO and VBO IDs are released.

    engine.gpu.VAO   vao;     // Vertex attribute bindings
    engine.gpu.IBO   ibo;     // Draw indexing
    
    engine.asset.Material material;
    
    this(
        engine.gpu.Shader.Family family,
        string filename,
        engine.asset.Material material,
        vec3 refpoint, vec3 saxis, float scale)
    {
        //-------------------------------------------------------------------------
        // Load file
        //-------------------------------------------------------------------------
        
        auto scene = new engine.asset.Scene(filename, fileinfo[filename].plane, fileinfo[filename].flags);
        super(scene.scene.mMeshes[0], scene.mGameSpace, refpoint, saxis, scale);
        
        //-------------------------------------------------------------------------
        // Create buffers for VBOs
        //-------------------------------------------------------------------------
        
        auto pos = new vec3[](mesh.mNumVertices);
        auto uv  = new vec2[](mesh.mNumVertices);
        auto t   = new vec3[](mesh.mNumVertices);
        auto b   = new vec3[](mesh.mNumVertices);
        auto n   = new vec3[](mesh.mNumVertices);

        //-------------------------------------------------------------------------
        // Fill them with postprocessed values
        //-------------------------------------------------------------------------

        for(int i = 0; i < mesh.mNumVertices; i++)
        {
            pos[i] = vec3(mPostProcess * vec4(mGameSpace * tovec3(mesh.mVertices[i]), 1));
            //pos[i] = mGameSpace * tovec3(mesh.mVertices[i]);

            t[i]   = mGameSpace * tovec3(mesh.mTangents[i]);
            b[i]   = mGameSpace * tovec3(mesh.mBitangents[i]);
            n[i]   = mGameSpace * tovec3(mesh.mNormals[i]);

            uv[i]  = tovec2(mesh.mTextureCoords[0][i]);
        }

        {
            auto bb = AABBT!(float).from_points(pos);
            Log << format("AABB (%f - %f), (%f - %f), (%f - %f)",
                bb.min.x, bb.max.x,
                bb.min.y, bb.max.y,
                bb.min.z, bb.max.z
            );
        }

        //-------------------------------------------------------------------------

        struct Face { ushort a, b, c; }
        auto faces = new Face[](mesh.mNumFaces);

        for(int i = 0; i < mesh.mNumFaces; i++)
        {
            auto face = mesh.mFaces[i];
            enforce(face.mNumIndices == 3);
            faces[i].a = cast(ushort)face.mIndices[0];
            faces[i].b = cast(ushort)face.mIndices[1];
            faces[i].c = cast(ushort)face.mIndices[2];
        }

        ibo = new engine.gpu.IBO(cast(ushort[])faces, GL_TRIANGLES);

        //-------------------------------------------------------------------------
        // Make it GPU VBOs (Vertex Buffer Object) and IBO (vertex indexing array)
        // Here we could use some kind of magic: we can extract shader uniforms
        // and vertex attributes, and then bind them to VBOs with same names.
        //-------------------------------------------------------------------------

        engine.gpu.VBO[string] vbos = [
            "vert.pos": new engine.gpu.VBO(pos),
            "vert.uv": new engine.gpu.VBO(uv),
            "vert.T": new engine.gpu.VBO(t),
            "vert.B": new engine.gpu.VBO(b),
            "vert.N": new engine.gpu.VBO(n),
        ];

        //-------------------------------------------------------------------------
        // Create VAO to bind buffers together (automatize buffer bindings).
        // NOTICE: We go through _shader_family_ attributes, and locate them
        // from our table: this way, if you have messed with shader families,
        // this part crashes :)
        //-------------------------------------------------------------------------

        vao = new engine.gpu.VAO();

        vao.bind();
        foreach(attrib; family.attributes.keys())
        {
            ERRORIF(!(attrib in vbos), format("Attribute '%s' not found.", attrib));
            
            auto vbo = vbos[attrib];
            family.attrib(attrib, vbo.type, vbo);
        }
        ibo.bind();
        vao.unbind();
        ibo.unbind();

        this.material = material;
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

    //*
    engine.asset.gPlane = engine.asset.Plane.XY;
    auto mView = mat4.look_at(vec3(0, -2, 0.5), vec3(0, 0, 0.5), vec3(0, 0, 1));
    auto pLight = vec3(2, -2, 2);
    /*/
    engine.asset.gPlane = engine.asset.Plane.XZ;
    auto mView = mat4.look_at(vec3(0, 0.5, 2.0), vec3(0, 0.5, 0), vec3(0, 1, 0));
    auto pLight = vec3(2, 2, 2);
    /**/
    
    /*
    mat4 mView = mat4(
        vec4( 1,  0,  0,  0.0),
        vec4( 0,  0,  1, -0.5),
        vec4( 0, -1,  0, -2.0),
        vec4( 0,  0,  0,  1),
    );
    /**/
    Log << to!string(mView);
    Log << (engine.asset.handness(mView) ? "Right" : "Left");

    //-------------------------------------------------------------------------
    // Load assets: This part should be simplified with Lua, allowing us to
    // create scripts to bind meshes and materials (in case where they are
    // not bind in the asset file itself).
    //-------------------------------------------------------------------------

    static if(0) auto model = new Model(
        shader.family,
        "data/Girl/Girl.dae",
        engine.asset.loadmaterial("data/Girl/Girl_cm.png"),
        vec3(0.5, 0.5, 0.0), vec3(0, 0, 1), 1.0
        //vec3(0.5, 0.0, 0.5), vec3(0, 1, 0), 1.0
    );

    static if(1) auto model = new Model(
        state.shader.family,
        "../../engine/stock/generic/mesh/Suzanne/Suzanne.obj",
        engine.asset.loadmaterial(vec4(0.5, 0.5, 0.5, 1)),
        vec3(0.5, 0.5, 0.0), vec3(0, 0, 1), 1.0
        //vec3(0.5, 0.0, 0.5), vec3(0, 1, 0), 1.0
    );

    static if(0) auto model = new Model(
        state.shader.family,
        "../../engine/stock/generic/mesh/Cube/Cube.dae",
        engine.asset.loadmaterial(
            //vec4(0.5, 0.5, 0.5, 1),
            "../../engine/stock/generic/tiles/BrickWall1/ColorMap.png",
            "../../engine/stock/generic/mesh/Cube/NormalMap.png",
            //"../../engine/stock/generic/tiles/BrickWall1/NormalMap.png",
            //engine.asset.loadnormalmap("../../engine/stock/generic/tiles/AlienCarving/NormalMap.png"),
            //engine.asset.loadnormalmap("../../engine/stock/generic/mesh/Cube/NormalMap.png"),
            //engine.asset.loadnormalmap(vec4(0.5, 0.5, 1, 0)
        ),
        vec3(0.5, 0.5, 0.0), vec3(0, 0, 1), 1.0,
    );

    static if(0) auto model = new Model(
        state.shader.family,
        "../../engine/stock/generic/mesh/Cube/CubeWrap.obj",
        engine.asset.loadmaterial(
            "../../engine/stock/generic/tiles/AlienCarving/ColorMap.png",
            "../../engine/stock/generic/tiles/AlienCarving/NormalMap.png"

            //"../../engine/stock/generic/tiles/Concrete/Crusty/ColorMap.png",
            //"../../engine/stock/generic/tiles/Concrete/Crusty/NormalMap.png"
        ),
        vec3(0.5, 0.5, 0.0), vec3(0, 0, 1), 1.0
    );

    static if(0) auto model = new Model(
        state.shader.family,
        "../../engine/stock/generic/mesh/Chess/king.obj",
        engine.asset.loadmaterial(vec4(0.5, 0.5, 0.5, 1)),
        //vec3(0.5, 0.5, 0.0), vec3(0, 0, 1), 1.0
        vec3(0.5, 0.0, 0.5), vec3(0, 1, 0), 1.0
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

    //*************************************************************************
    // Drawing
    //*************************************************************************

    void draw()
    {
        static float angle = 0;
        angle += 0.005;

        mat4 mModel = mat4.identity().rotate(angle, (engine.asset.gPlane == engine.asset.Plane.XY) ? vec3(0, 0, 1) : vec3(0, 1, 0));
        mat4 mLight = mat4.identity();//.rotate(angle, vec3(0, 0, -1));
        
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
            uniform("material.colormap", model.material.colormap, 0);
            uniform("material.normalmap", model.material.normalmap, 1);
        }
        model.draw();
        
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
        
        model.draw();
        /**/
    }

    //*************************************************************************
    // Enable profiling and frequent update
    //*************************************************************************

    game.Profile.enable();

    void report()
    {
        game.Profile.log("Perf");
        engine.Track.report();
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

