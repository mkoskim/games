//*****************************************************************************
//
// Creating vertex buffer objects on GPU, and index buffers.
//
//*****************************************************************************

module engine.gpu.buffers;

import engine.gpu.util;
import engine.gpu.types;

//-------------------------------------------------------------------------
// Vertex data buffers (VBO, Vertex Buffer Object)
//-------------------------------------------------------------------------

class VBO
{
    GLuint ID;

    this(void* buffer, size_t length, size_t elemsize, GLenum mode = GL_STATIC_DRAW)
    {
        debug Track.add(this);

        checkgl!glGenBuffers(1, &ID);

        bind();
        checkgl!glBufferData(GL_ARRAY_BUFFER, length * elemsize, buffer, mode);
        unbind();
    }

    //---------------------------------------------------------------------

    GLenum type;

    this(GLenum type, void* buffer, size_t length, size_t elemsize)
    {
        this(buffer, length, elemsize);
        this.type = type;
    }
    
    this(vec3[] buffer) { this(GL_FLOAT_VEC3, buffer.ptr, buffer.length, vec3.sizeof); }
    this(vec2[] buffer) { this(GL_FLOAT_VEC2, buffer.ptr, buffer.length, vec2.sizeof); }

    //---------------------------------------------------------------------

    ~this()
    {
        debug Track.remove(this);
        checkgl!glDeleteBuffers(1, &ID);
    }

    //---------------------------------------------------------------------

    void bind()   { checkgl!glBindBuffer(GL_ARRAY_BUFFER, ID); }
    void unbind() { checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0); }
}

//-------------------------------------------------------------------------
// Index Buffer Object
// TODO: Add ranged draw.
//-------------------------------------------------------------------------

class IBO
{
    GLuint ID;
    GLuint length;
    GLuint drawmode;

    this(ushort[] faces, GLint drawmode, GLenum mode = GL_STATIC_DRAW)
    {
        debug Track.add(this);
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
        debug Track.remove(this);
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

class VAO
{
    uint ID;

    this() {
        debug Track.add(this);
        checkgl!glGenVertexArrays(1, &ID);
    }
    
    ~this() {
        debug Track.remove(this);
        checkgl!glDeleteVertexArrays(1, &ID);
    }

    void bind() { checkgl!glBindVertexArray(ID); }
    void unbind() { checkgl!glBindVertexArray(0); }
}

