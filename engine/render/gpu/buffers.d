//*****************************************************************************
//
// Creating vertex buffer objects on GPU, and index buffers.
//
//*****************************************************************************

module engine.render.gpu.buffers;

import engine.render.util;

import engine.render.gpu.types;

//-------------------------------------------------------------------------
// Vertex data buffers (VBO, Vertex Buffer Object)
//-------------------------------------------------------------------------

protected class VBO
{
    GLuint ID;

    this(void* buffer, size_t length, size_t elemsize, GLenum mode = GL_STATIC_DRAW)
    {
        Track.add(this);

        checkgl!glGenBuffers(1, &ID);

        bind();
        checkgl!glBufferData(GL_ARRAY_BUFFER, length * elemsize, buffer, mode);
        unbind();
    }

    ~this()
    {
        Track.remove(this);
        checkgl!glDeleteBuffers(1, &ID);
        //writeln("~VBO.this: ", ID);
    }

    //---------------------------------------------------------------------

    void bind()   { checkgl!glBindBuffer(GL_ARRAY_BUFFER, ID); }
    void unbind() { checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0); }
}

//-------------------------------------------------------------------------
// Index Buffer Object
// TODO: Add ranged draw.
//-------------------------------------------------------------------------

protected class IBO
{
    GLuint ID;
    GLuint length;
    GLuint drawmode;

    this(GLint drawmode, ushort[] faces, GLenum mode = GL_STATIC_DRAW)
    {
        Track.add(this);
        length = cast(uint)faces.length;
        this.drawmode = drawmode;

        checkgl!glGenBuffers(1, &ID);
        checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ID);
        checkgl!glBufferData(GL_ELEMENT_ARRAY_BUFFER,
            faces.length * ushort.sizeof,
            faces.ptr,
            mode
        );
        checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }

    ~this()
    {
        Track.remove(this);
        checkgl!glDeleteBuffers(1, &ID);
    }

    void bind() { checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ID); }
    void unbind() { checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); }

    void draw() {
        checkgl!glDrawElements(drawmode, length, GL_UNSIGNED_SHORT, null);
    }
}

//-------------------------------------------------------------------------
// Vertex Array Object
//-------------------------------------------------------------------------

protected class VAO
{
    uint ID;

    this()  { checkgl!glGenVertexArrays(1, &ID); }
    ~this() { checkgl!glDeleteVertexArrays(1, &ID); }

    void bind() { checkgl!glBindVertexArray(ID); }
    void unbind() { checkgl!glBindVertexArray(0); }
}

