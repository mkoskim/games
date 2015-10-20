//*****************************************************************************
//
// 3D scene rendering
//
//*****************************************************************************

module engine.render.scene3d;

public {
    import engine.render.loader.mesh;

    import engine.render.gpu.texture;

    import engine.render.scene3d.types.transform;
    import engine.render.scene3d.types.bounds;
    import engine.render.scene3d.types.material;
    import engine.render.scene3d.types.model;
    import engine.render.scene3d.types.node;
    import engine.render.scene3d.types.view;
    import engine.render.scene3d.types.light;

    import shaders = engine.render.scene3d.shader: Default3D, Flat3D;
    import engine.render.scene3d.state;
    import engine.render.scene3d.batch;
    import engine.render.scene3d.layer;
    import engine.render.scene3d.pipeline;

    import gl3n.linalg;
}

