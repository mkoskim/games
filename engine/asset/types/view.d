//*****************************************************************************
//
// Views handle rendering settings: projection, lights, and such.
//
//*****************************************************************************

module engine.asset.types.view;

//-----------------------------------------------------------------------------

public import gl3n.frustum: Frustum, OUTSIDE, INTERSECT, INSIDE;

import engine.game.instance;

import engine.asset.util;
import engine.asset.types.transform;

//-----------------------------------------------------------------------------
// TODO: Combine View and Camera
//-----------------------------------------------------------------------------

abstract class View
{
    abstract mat4 mView();
    abstract mat4 mProjection();

    mat4 mModelView(mat4 mModel) { return mView() * mModel; }
    mat4 mMVP(mat4 mModel) { return mProjection() * mView() * mModel; }

    abstract Frustum frustum();

    // Viewspace coordinate computations

    vec3 viewspace(vec3 pos) {
        return (mView() * vec4(pos, 1)).xyz;
    }

    vec3 viewspace(mat4 mModel, vec3 pos = vec3(0, 0, 0)) {
        return (mModelView(mModel) * vec4(pos, 1)).xyz;
    }

    // Clipspace coordinate computations

    vec4 clipspace(vec3 pos) {
        return mProjection() * mView() * vec4(pos, 1);
    }

    vec4 clipspace(mat4 mModel, vec3 pos) {
        return mMVP(mModel) * vec4(pos, 1);
    }

    // Screen coordinates (projecting)

    vec3 project(vec4 p) { return vec3(p.x/p.w, p.y/p.w, p.z/p.w); }
    vec3 project(vec3 pos) { return project(clipspace(pos)); }
    vec3 project(mat4 mModel, vec3 pos) { return project(clipspace(mModel, pos)); }
}

//-----------------------------------------------------------------------------

class Camera : View
{
    Transform transform;
    Grip grip;

    mat4 projection;
    Frustum _frustum;

    //-------------------------------------------------------------------------

    override Frustum frustum() { return _frustum; }

    //-------------------------------------------------------------------------

    this(mat4 projection, Transform transform)
    {
        this.projection = projection;
        this._frustum = Frustum(mProjection());

        this.transform = transform;
        this.grip = transform.grip;
    }

    //-------------------------------------------------------------------------

    override mat4 mView() { return transform.mModel().inverse(); }
    override mat4 mProjection() { return projection; }

    //-------------------------------------------------------------------------

    void setProjection(float fov, float near, float far)
    {
        projection = mat4.perspective(
            screen.width, screen.height,
            fov,
            near, far
        );
        _frustum = Frustum(projection);
    }

    //-------------------------------------------------------------------------
    // By default, we add movable cameras
    //-------------------------------------------------------------------------
    
    static Camera basic3D(float near, float far, Transform transform)
    {
        return new Camera(
            mat4.perspective(
                screen.width, screen.height,
                60,
                near, far
            ),
            transform
        );
    }

    static Camera basic3D(float near, float far, vec3 pos)
    {
        return basic3D(near, far, Grip.movable(pos));
    }

    //-------------------------------------------------------------------------

    static Camera topleft2D(float unitlength = 1)
    {
        return new Camera(
            mat4.orthographic(
                0, screen.width/unitlength,
                screen.height/unitlength, 0,
                -1, 1
            ),
            Grip.movable()
        );
    }
}

