//*****************************************************************************
//
// Blanko shader does nothing. It can be used to measure CPU load.
//
//*****************************************************************************

module engine.render.shaders.blanko;

import engine.render.util;
import engine.render.shaders.base;
import engine.render.bone;
import engine.render.mesh;
import engine.render.material;
import engine.render.view;

class Blanko : Shader
{
    static Shader create()
    {
        static Blanko instance = null;
        if(!instance) instance = new Blanko();
        return instance;
    }

    //-------------------------------------------------------------------------

    override protected void addVBOs(VAO vao, Mesh mesh) { }

    override void loadView(View cam) { }
    override void loadMaterial(Material mat) { }

    override void render(Bone grip, VAO vao) { }
    override void render(Bone[] grips, VAO vao) { }

    //-------------------------------------------------------------------------

    private this() { super(); }
}

