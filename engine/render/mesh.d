//*****************************************************************************
//
// Mesh
//
// Mesh is an intermediate object between model sources (files, geometry
// generators) and shaders. At the moment, Mesh data buffers can directly be
// used as VBO data buffers (that is, Mesh is close to VAO), but this can be
// changed in future.
//
// It is intended that you can modify (move, rotate, scale) Mesh data before
// uploading it to shader.
//
//*****************************************************************************

module engine.render.mesh;

//-----------------------------------------------------------------------------

import engine.render.util;
import engine.render.shaders.gputypes;

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------

class Mesh
{
    //-------------------------------------------------------------------------
    //
    // 'Shader-compatible' packed & interleaved vertex data. Using these makes
    // processing a bit harder, but saves us from creating the buffer inside
    // Shader.upload().
    //
    //-------------------------------------------------------------------------
    
    struct VERTEX
    {
        vec3 pos;

        fvec2x16b uv;
        ivec4x8b normal;    // TODO: GL_INT_2_10_10_10_REV
        ivec4x8b tangent;   // TODO: GL_INT_2_10_10_10_REV

        uint[2] padding;

        //---------------------------------------------------------------------

        static assert(VERTEX.sizeof == 32);

        //---------------------------------------------------------------------

        this(vec3 pos, vec3 norm, vec2 uv)
        {
            this.pos = pos;
            this.uv = uv;
            this.normal = vec4(norm, 0).normalized();
            this.tangent = vec4(0, 0, 0, 0);
        }
    }

    uint mode;
    VERTEX[] vertices;
    ushort[] faces;

    //-------------------------------------------------------------------------

    this(uint mode)
    {
        this.mode = mode;
    }

    //-------------------------------------------------------------------------

    ushort addvertex(vec3 pos, vec2 uv, vec3 normal)
    {
        vertices ~= VERTEX(pos, normal, uv);
        return cast(ushort)(vertices.length - 1);
    }

    ushort addvertex(vec3 coord, vec2 uv) { return addvertex(coord, uv, vec3(0, 0, 0)); }
    ushort addvertex(vec3 coord, vec3 n)  { return addvertex(coord, vec2(0, 0), n); }
    ushort addvertex(vec3 coord)          { return addvertex(coord, vec2(0, 0), vec3(0, 0, 0)); }

    //-------------------------------------------------------------------------
    // TODO: We probably need own classes for point & line groups, no need
    // to use Mesh for those
    //-------------------------------------------------------------------------

    void addface(ushort[] indices) { faces ~= indices; }

    void addface(ushort point) { faces ~= point; }
    void addface(ushort p1, ushort p2) { faces ~= [ p1, p2 ]; }
    void addface(ushort p1, ushort p2, ushort p3) { faces ~= [ p1, p2, p3 ]; }

    //-------------------------------------------------------------------------
    // Raw transforms
    //-------------------------------------------------------------------------

    Mesh transform(mat4 M)
    {
        foreach(i; 0 .. vertices.length)
        {
            vertices[i].pos = (M * vec4(vertices[i].pos, 1)).xyz;
            vertices[i].normal.pack(M * vertices[i].normal.unpack());
        }
        return this;
    }

    Mesh move(vec3 delta)
    {
        foreach(i; 0 .. vertices.length) vertices[i].pos += delta;
        return this;
    }

    Mesh move(float x, float y, float z)
    {
        return move(vec3(x, y, z));
    }

    Mesh scale(float factor)
    {
        foreach(i; 0 .. vertices.length) vertices[i].pos *= factor;
        return this;
    }

    //-------------------------------------------------------------------------
    // UV transforms
    //-------------------------------------------------------------------------

    Mesh uv_scale(vec2 factor)
    {
        foreach(i; 0 .. vertices.length)
        {
            vec2 uv = vertices[i].uv.unpack();
            uv.x *= factor.x;
            uv.y *= factor.y;
            vertices[i].uv.pack(uv);
        }
        return this;
    }

    Mesh uv_scale(float factor)
    {
        return uv_scale(vec2(factor, factor));
    }

    Mesh uv_move(vec2 delta)
    {
        foreach(i; 0 .. vertices.length)
        {
            vec2 uv = vertices[i].uv.unpack();
            uv += delta;
            vertices[i].uv.pack(uv);
        }
        return this;
    }

    Mesh uv_move(float x, float y)
    {
        return uv_move(vec2(x, y));
    }

    //-------------------------------------------------------------------------
    //
    // Computing triangle tangents, see e.g.
    //
    //      http://www.terathon.com/code/tangent.html
    //      http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-13-normal-mapping/
    //
    //-------------------------------------------------------------------------

    void computeTangents()
    {
        assert(mode == GL_TRIANGLES);

        vec3[] tan1 = new vec3[vertices.length];
        vec3[] tan2 = new vec3[vertices.length];

        foreach(i; 0 .. vertices.length)
        {
            tan1[i] = vec3(0, 0, 0);
            tan2[i] = vec3(0, 0, 0);
        }

        for(int i = 0; i < faces.length; i += 3)
        {
            VERTEX*
                v1 = &vertices[faces[i]],
                v2 = &vertices[faces[i+1]],
                v3 = &vertices[faces[i+2]];

            //vec2 st1 = v2.uv - v1.uv;
            //vec2 st2 = v3.uv - v1.uv;
            vec2 st1 = v2.uv.unpack() - v1.uv.unpack();
            vec2 st2 = v3.uv.unpack() - v1.uv.unpack();

            if(!st1.magnitude() || !st2.magnitude()) continue;

            vec3 p1  = v2.pos - v1.pos;
            vec3 p2  = v3.pos - v1.pos;

            float r = 1.0F / (st1.x * st2.y - st1.y * st2.x);

            vec3 sdir = (p1 * st2.y - p2 * st1.y) * r;
            vec3 tdir = (p2 * st1.x - p1 * st2.x) * r;

            tan1[faces[i]]   += sdir;
            tan1[faces[i+1]] += sdir;
            tan1[faces[i+2]] += sdir;

            tan2[faces[i]]   += tdir;
            tan2[faces[i+1]] += tdir;
            tan2[faces[i+2]] += tdir;
        }

        foreach(i; 0 .. vertices.length)
        {
            vec3 n = vertices[i].normal.unpack().xyz;
            vec3 t = tan1[i];
            
            // Gram-Schmidt orthogonalize
            // Calculate handedness
            vertices[i].tangent.pack(vec4(
                (t - n * n.dot(t)).normalized(),
                ((n.cross(t).dot(tan2[i]) < 0.0F) ? -1.0F : 1.0F)
            ));
        }
    }
}

