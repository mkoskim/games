//*****************************************************************************
//
// 3D scene rendering
//
//*****************************************************************************

module engine.render.scene3d;

public {
    import engine.render.gpu.texture;

    import engine.asset.types.transform;
    import engine.asset.types.bounds;
    import engine.asset.types.material;
    import engine.asset.types.model;
    import engine.asset.types.node;
    import engine.asset.types.mesh;
    import engine.asset.types.view;
    import engine.asset.types.light;

    import engine.render.scene3d.feeder;
    import engine.render.scene3d.batch;
    import engine.render.scene3d.asset;
    import engine.render.scene3d.pipeline;

    import gl3n.linalg;
}


