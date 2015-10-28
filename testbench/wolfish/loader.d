//*****************************************************************************
//*****************************************************************************
//
// Wolfish loader
//
//*****************************************************************************
//*****************************************************************************

module loader;

import engine;

//*****************************************************************************
//
// Pipeline construction: This demonstrates how to create multiple batches
// with different shaders and rendering order. We create following
// batches:
//
//      name            shader      order
//
//      walls           default     solid (front2back)
//      props           default     solid
//      floors          default     solid
//      transparent     default     transparent (back2front)
//
//*****************************************************************************

scene3d.Pipeline createPipeline()
{
    auto pipeline = new scene3d.Pipeline();

    //-------------------------------------------------------------------------
    // Create and configure shaders and (rendering) states for later use. We
    // usually need at least solid and transparent batches.
    //-------------------------------------------------------------------------

    auto shaders = pipeline.shaders;
    
    shaders.Default3D("default");
    //shaders.Flat3D("flat");
    
    {   auto shader = shaders["default"];
        shader.options["fog.enabled"] = true;
        shader.options["fog.start"] = 15.0;
        shader.options["fog.end"]   = 20.0;
        shader.options["fog.color"] = vec4(0.0, 0.0, 0.0, 1);
    }

    auto states = pipeline.states;

    states.Solid3D("solid", shaders["default"]);
    states.Transparent3D("transparent", shaders["default"]);

    //-------------------------------------------------------------------------
    // Create batches for objects. In general, the simpler and faster it is
    // to render an object and the more it can occlude other things, the earlier
    // we want render it - this way, Z buffering prevents us to do wasted work.
    //
    // We give names to batches, so that our level loaders can place objects
    // to correct rendering phase.
    //
    //-------------------------------------------------------------------------

    auto batches = pipeline.batches;

    batches.add("walls",       states["solid"]);
    batches.add("props",       states["solid"]);
    batches.add("floors",      states["solid"]);
    batches.add("transparent", states["transparent"]);

    return pipeline;
}

//*****************************************************************************
//
// Maze: This demonstrates/experiments how games can load levels. Key points:
//
// 1) Ready-made pipeline: This can already contain items that are shared
//    between levels (e.g. player objects).
//
// 2) Level asset management: When changing level, we need to get rid of
//    objects needed by previous level.
//
//*****************************************************************************

void loadmodels(scene3d.Pipeline pipeline)
{
    //---------------------------------------------------------------------
    // Clear previous level
    //---------------------------------------------------------------------

    auto asset = pipeline.assets.add("maze");

    string path(string filename) { return "engine/stock/unsorted/" ~ filename; }

    //---------------------------------------------------------------------
    // Load meshes
    //---------------------------------------------------------------------

    asset.upload("wall",   blob.wavefront.loadmesh(path("mesh/Cube/CubeWrap.obj")));
    asset.upload("floor",  blob.wavefront.loadmesh(path("mesh/Cube/Floor.obj")));
    asset.upload("monkey", blob.wavefront.loadmesh(path("mesh/Suzanne/Suzanne.obj")).scale(0.66));
    
    //---------------------------------------------------------------------
    // Load materials
    //---------------------------------------------------------------------

    auto material = pipeline.assets.material;     // Material loader

    asset.upload("CaveWall", material(
        path("tiles/CaveWall/ColorMap.png"),
        path("tiles/CaveWall/NormalMap.png"),
        1.00));

    asset.upload("CrackedPlaster", material(
        path("tiles/CrackedPlaster/ColorMap.png"),
        path("tiles/CrackedPlaster/NormalMap.png"),
        0.95));

    asset.upload("SantaFeStucco", material(
        //"engine/stock/tiles/SantaFeStucco/ColorMap.png",
        path("tiles/CaveWall/ColorMap.png"),
        path("tiles/SantaFeStucco/NormalMap.png"),
        0.95));

    asset.upload("TanStucco", material(
        //"engine/stock/tiles/SantaFeStucco/ColorMap.png",
        path("tiles/TanStucco/ColorMap.png"),
        path("tiles/TanStucco/NormalMap.png"),
        0.95));

    asset.upload("BrickWall", material(
        path("tiles/BrickWall1/ColorMap.png"),
        path("tiles/BrickWall1/NormalMap.png"),
        0.95));

    asset.upload("GraniteWall", material(
        path("tiles/GraniteWall/ColorMap.png"),
        path("tiles/GraniteWall/NormalMap.png"),
        0.95));

    asset.upload("CrustyConcrete", material(
        path("tiles/Concrete/Crusty/ColorMap.png"),
        path("tiles/Concrete/Crusty/NormalMap.png"),
        0.95));

    asset.upload("DirtyConcrete", material(
        path("tiles/Concrete/Dirty/ColorMap.png"),
        path("tiles/Concrete/Dirty/NormalMap.png"),
        0.95));

    asset.upload("CarvedSandstone", material(
        path("tiles/CarvedSandstone/ColorMap.png"),
        //"engine/stock/tiles/CaveWall/ColorMap.png",
        //vec3(0.5, 0.4, 0.2),
        path("tiles/CarvedSandstone/NormalMap.png"),
        0.95));

    asset.upload("AlienCarving", material(
        //"engine/stock/tiles/AlienCarving/ColorMap.png",
        vec4(0.75, 0.5, 0.25, 1),
        path("tiles/AlienCarving/NormalMap.png"),
        0.15));

    asset.upload("MetallicAssembly", material(
        //"engine/stock/tiles/MetallicAssembly/ColorMap.png",
        vec4(0.5, 0.5, 0.5, 1),
        path("tiles/MetallicAssembly/NormalMap.png"),
        0.15));

    asset.upload("Glass", material(
        vec4(0.8, 0.8, 0.9, 0.3),
        "engine/stock/unsorted/tiles/SantaFeStucco/NormalMap.png",
        0.50));

    //---------------------------------------------------------------------

    auto floormat = asset.upload("Floor", asset.materials["GraniteWall"]);
    asset.upload("PaintedFloor", material(
        vec4(0.25, 0.25, 0.25, 1),
        floormat.normalmap,
        floormat.roughness));
        
    //---------------------------------------------------------------------
    // Make shortcuts to pipeline batches
    //---------------------------------------------------------------------

    auto batches = pipeline.batches;
    
    auto walls  = batches["walls"];
    auto floors = batches["floors"];
    auto props  = batches["props"];
    auto transparent = batches["transparent"];
    
    //---------------------------------------------------------------------
    // Create model lookup table
    //---------------------------------------------------------------------
    
    asset.upload("1", walls, "wall", "CaveWall");
    asset.upload("2", walls, "wall", "BrickWall");
    asset.upload("3", walls, "wall", "DirtyConcrete");
    asset.upload("4", walls, "wall", "MetallicAssembly");
    asset.upload("5", walls, "wall", "AlienCarving");
    asset.upload("#", asset("1"));

    asset.upload(" ", floors, "floor", "Floor");
    asset.upload("n", floors, "floor", "PaintedFloor");

    asset.upload("X", transparent, "monkey", "Glass");
}

