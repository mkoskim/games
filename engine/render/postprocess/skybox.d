//*****************************************************************************
//
// Rendering skybox
//
//*****************************************************************************

module engine.render.postprocess.skybox;

import engine.render.util;
import engine.render.gpu.texture;
import engine.render.gpu.buffers;
import engine.render.gpu.shader;
import engine.render.gpu.state;
import engine.render.gpu.framebuffer;

//-----------------------------------------------------------------------------
//
// SkyBox is (currently) a special object in rendering path. It is currently
// manually inserted to drawing phase, but in future we probably want to have
// a framework to support these kinds of objects.
//
//-----------------------------------------------------------------------------

class SkyBox
{
    //-------------------------------------------------------------------------

    Cubemap cubemap;

    this(Cubemap cubemap, Framebuffer target)
    {
        this.cubemap = cubemap;

        if(!shader) create(target);
    }

    //-------------------------------------------------------------------------
    // Dedicated (Singleton) SkyMap Shader. For feeding Vertex Shader,
    // we create a unit cube by hand.
    //-------------------------------------------------------------------------

    static Shader shader;
    static State state;

    static VAO vao;
    static VBO vbo;

    static const GLfloat[] vertbuf = [
        -1.0f,  1.0f, -1.0f,
        -1.0f, -1.0f, -1.0f,
         1.0f, -1.0f, -1.0f,
         1.0f, -1.0f, -1.0f,
         1.0f,  1.0f, -1.0f,
        -1.0f,  1.0f, -1.0f,

        -1.0f, -1.0f,  1.0f,
        -1.0f, -1.0f, -1.0f,
        -1.0f,  1.0f, -1.0f,
        -1.0f,  1.0f, -1.0f,
        -1.0f,  1.0f,  1.0f,
        -1.0f, -1.0f,  1.0f,

         1.0f, -1.0f, -1.0f,
         1.0f, -1.0f,  1.0f,
         1.0f,  1.0f,  1.0f,
         1.0f,  1.0f,  1.0f,
         1.0f,  1.0f, -1.0f,
         1.0f, -1.0f, -1.0f,

        -1.0f, -1.0f,  1.0f,
        -1.0f,  1.0f,  1.0f,
         1.0f,  1.0f,  1.0f,
         1.0f,  1.0f,  1.0f,
         1.0f, -1.0f,  1.0f,
        -1.0f, -1.0f,  1.0f,

        -1.0f,  1.0f, -1.0f,
         1.0f,  1.0f, -1.0f,
         1.0f,  1.0f,  1.0f,
         1.0f,  1.0f,  1.0f,
        -1.0f,  1.0f,  1.0f,
        -1.0f,  1.0f, -1.0f,

        -1.0f, -1.0f, -1.0f,
        -1.0f, -1.0f,  1.0f,
         1.0f, -1.0f, -1.0f,
         1.0f, -1.0f, -1.0f,
        -1.0f, -1.0f,  1.0f,
         1.0f, -1.0f,  1.0f
    ];

    void create(Framebuffer target)
    {
        shader = new Shader("engine/render/postprocess/glsl/skybox.glsl");

        vao = new VAO();
        vao.bind();

        vbo = new VBO(
            cast(void*)vertbuf.ptr,
            vertbuf.length,
            GLfloat.sizeof
        );
        vbo.bind();

        shader.attrib!(vec3)("vert_pos", 0, 0);

        vao.unbind();
        vbo.unbind();

        state = new State(target, shader, (){});
    }

    void draw(mat4 view, mat4 projection)
    {
        state.activate();
        shader.uniform("view", Variant(view));
        shader.uniform("projection", Variant(projection));
        shader.texture("skybox", 0, cubemap);        

            checkgl!glEnable(GL_CULL_FACE);
            checkgl!glCullFace(GL_BACK);
            checkgl!glFrontFace(GL_CCW);
            checkgl!glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            checkgl!glEnable(GL_DEPTH_TEST);
            checkgl!glDepthFunc(GL_LEQUAL);
            checkgl!glDisable(GL_BLEND);

        vao.bind();
        glDrawArrays(GL_TRIANGLES, 0, 12*3);
        vao.unbind();
    }
}

