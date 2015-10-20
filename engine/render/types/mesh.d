//*****************************************************************************
//
// Mesh
//
// Mesh is an intermediate object between model sources (files, geometry
// generators) and shaders. At the moment, Mesh data buffers can directly be
// used as VBO data buffers (that is, Mesh is close to VAO), but this is
// changed in future.
//
// It is intended that you can modify (move, rotate, scale) Mesh data before
// uploading it to shader.
//
//*****************************************************************************

module engine.render.types.mesh;

//-----------------------------------------------------------------------------

import engine.render.util;

//*****************************************************************************
//
//*****************************************************************************

class Mesh
{
    //*************************************************************************

    struct VERTEX
    {
        vec3 pos;
        vec2 uv;
        vec3 normal;
        vec4 tangent;

        this(vec3 pos, vec2 uv, vec3 normal) {
            this.pos = pos;
            this.uv = uv;
            this.normal = normal;
        }
    }

    uint mode;
    VERTEX[] vertices;
    ushort[] faces;

    //*************************************************************************
    //
    // In practise, we currently support only GL_TRIANGLES. Groups of lines
    // or points are anyways worth of having separate implementation, but
    // GL_TRIANGLE_STRIP is definitely an additional mode to consider.
    //
    //*************************************************************************

    this(uint mode = GL_TRIANGLES)
    {
        Track.add(this);
        this.mode = mode;
    }

    ~this() { Track.remove(this); }

    //*************************************************************************

    ushort addvertex(vec3 pos, vec2 uv, vec3 normal)
    {
        vertices ~= VERTEX(pos, uv, normal);
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

    //*************************************************************************
    //
    // Mesh post-processing
    //
    //*************************************************************************

    Mesh transform(mat4 M)
    {
        foreach(i; 0 .. vertices.length)
        {
            vertices[i].pos = (M * vec4(vertices[i].pos, 1)).xyz;
            vertices[i].normal = (M * vec4(vertices[i].normal, 1)).xyz;
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
            vec2 uv = vertices[i].uv;
            uv.x *= factor.x;
            uv.y *= factor.y;
            vertices[i].uv = uv;
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
            vec2 uv = vertices[i].uv;
            uv += delta;
            vertices[i].uv = uv;
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
            vec2 st1 = v2.uv - v1.uv;
            vec2 st2 = v3.uv - v1.uv;

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
            vec3 n = vertices[i].normal;
            vec3 t = tan1[i];
            
            // Gram-Schmidt orthogonalize
            // Calculate handedness
            vertices[i].tangent = vec4(
                (t - n * n.dot(t)).normalized(),
                ((n.cross(t).dot(tan2[i]) < 0.0F) ? -1.0F : 1.0F)
            );
        }
    }
}

