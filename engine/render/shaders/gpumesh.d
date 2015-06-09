//*****************************************************************************
//
// Creating vertex buffer objects on GPU, and index buffers.
//
//*****************************************************************************

module engine.render.shaders.gpumesh;

import engine.render.util;

import engine.render.shaders.gputypes;

/*
import engine.render.mesh;
import engine.render.bound;
*/

//-------------------------------------------------------------------------
// Vertex data buffers (VBO, Vertex Buffer Object)
//-------------------------------------------------------------------------

/*
static void attrib(alias field)(VBO vbo, string name)
{
    vbo.attrib!(typeof(field))(name, field.offsetof);
}
*/

protected class VBO
{
    GLuint ID;      // VBO ID
    ulong rowsize; // Data row size

    this(void* buffer, size_t length, size_t elemsize, uint mode = GL_STATIC_DRAW)
    {
        checkgl!glGenBuffers(1, &ID);
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, ID);
        checkgl!glBufferData(GL_ARRAY_BUFFER, length * elemsize, buffer, mode);
        checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0);

        rowsize = elemsize;
    }

    ~this()
    {
        checkgl!glDeleteBuffers(1, &ID);
        //writeln("~VBO.this: ", ID);
    }

    //---------------------------------------------------------------------

    void bind()   { checkgl!glBindBuffer(GL_ARRAY_BUFFER, ID); }
    void unbind() { checkgl!glBindBuffer(GL_ARRAY_BUFFER, 0); }

    //---------------------------------------------------------------------

    struct ATTRIB
    {
        GLenum type;        // GL_FLOAT, ...
        GLint elems;        // Number of elements in this attribute (1 .. 4)
        GLboolean normd;    // Normalized / not
        ulong offset;       // Offset in interleaved buffers
    }

    ATTRIB[string] attribs;

    void setattrib(string name, GLenum type, GLint elems, bool normalized, ulong offset) {
        attribs[name] = ATTRIB(
            //location("attrib", name),
            type,
            elems,
            normalized ? GL_TRUE : GL_FALSE,
            offset
        );
    }

    void attrib(T: vec2)(string name, ulong offset) { setattrib(name, GL_FLOAT, 2, false, offset); }
    void attrib(T: vec3)(string name, ulong offset) { setattrib(name, GL_FLOAT, 3, false, offset); }
    void attrib(T: vec4)(string name, ulong offset) { setattrib(name, GL_FLOAT, 4, false, offset); }

    void attrib(T: ivec4x8b)(string name, ulong offset) { setattrib(name, T.gltype, T.glsize, T.glnormd, offset); }
    void attrib(T: ivec3x10b)(string name, ulong offset) { setattrib(name, T.gltype, T.glsize, T.glnormd, offset); }
    void attrib(T: fvec2x16b)(string name, ulong offset) { setattrib(name, T.gltype, T.glsize, T.glnormd, offset); }

    void attrib(T)(string name, ulong offset) { throw new Error("Attribute type " ~ T.stringof ~ " not implemented."); }

    //-----------------------------------------------------------------

    void connect(GLint loc, string name)
    {
        ATTRIB attr = attribs[name];

        checkgl!glVertexAttribPointer(
            loc,                        // attribute location
            attr.elems,                 // size
            attr.type,                  // type
            attr.normd,                 // normalized?
            cast(int)rowsize,           // stride
            cast(void*)attr.offset      // array buffer offset
        );
        checkgl!glEnableVertexAttribArray(loc);
    }

    void disconnect(GLint loc)
    {
        checkgl!glDisableVertexAttribArray(loc);
    }

    //---------------------------------------------------------------------

    /*
    void connect() {
        bind();
        foreach(attr; attribs) connect(attr);
    }

    void disconnect() {
        foreach(attr; attribs) disconnect(attr);
        unbind();
    }
    */
}

//-------------------------------------------------------------------------

protected class IBO
{
    uint ID;
    uint length;
    uint drawmode;

    this(uint drawmode, ushort[] faces, uint mode = GL_STATIC_DRAW)
    {
        length = cast(uint)faces.length;
        this.drawmode = drawmode;

        checkgl!glGenBuffers(1, &ID);
        checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ID);
        checkgl!glBufferData(GL_ELEMENT_ARRAY_BUFFER,
            faces.length * ushort.sizeof,
            faces.ptr, mode
        );
        checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }

    ~this()
    {
        checkgl!glDeleteBuffers(1, &ID);
    }

    void connect() { checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ID); }
    void disconnect() { checkgl!glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); }

    void draw() {
        checkgl!glDrawElements(drawmode, length, GL_UNSIGNED_SHORT, null);
    }
}

