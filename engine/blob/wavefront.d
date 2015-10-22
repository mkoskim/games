//*****************************************************************************
//
// Loading Wavefront (.obj / .mtl) files
//
//*****************************************************************************

module engine.blob.wavefront;

//-----------------------------------------------------------------------------

import engine.blob.util;
import engine.blob.extract;

import engine.render.util;
import engine.render.loader.mesh;

import std.string;

//-----------------------------------------------------------------------------
//
// Vertex data extracted from face definition: For shader, vertex means
// all unique combinations of position, UV coordinates, normal and such. In
// OBJ file, these combinations are listed when specifying faces.
//
//-----------------------------------------------------------------------------

private struct VERTEX {
    uint v_ind, vt_ind, vn_ind;

    this(string vertex) {
        auto indices = vertex.split("/");

        foreach(i, index; indices) if(!index.length) indices[i] = "0";

        v_ind = to!uint(indices[0]);
        vt_ind = (indices.length > 1) ? to!uint(indices[1]) : 0;
        vn_ind = (indices.length > 2) ? to!uint(indices[2]) : 0;
    }

    string key() { return format("%u/%u/%u", v_ind, vt_ind, vn_ind); }
}

//-----------------------------------------------------------------------------
// 3 x vertex = triangle
//-----------------------------------------------------------------------------

private struct TRIANGLE {
    VERTEX[3] vertices;

    this(string v1, string v2, string v3) {
        vertices = [ VERTEX(v1), VERTEX(v2), VERTEX(v3) ];
    }
}

//-----------------------------------------------------------------------------
//
// Loading OBJ file is done in two passes. First pass reads in the lines and
// extract information "as is". Then, possible missing data (UV coordinates,
// normals) is computed. Finally, data is converted to a Mesh and returned
// to caller.
//
//-----------------------------------------------------------------------------

Mesh loadmesh(string filename)
{
    //-------------------------------------------------------------------------
    // Load file content
    //-------------------------------------------------------------------------

    string content = cast(string)extract(filename);

    //-------------------------------------------------------------------------
    // Information extracted from OBJ file
    //-------------------------------------------------------------------------

    vec3[] v;       // Vertices
    vec2[] vt;      // UV (texture) coords
    vec3[] vn;      // Vertex normals

    TRIANGLE[] f;   // Faces

    bool smoothing = false;

    //-------------------------------------------------------------------------
    // Process content line by line
    //-------------------------------------------------------------------------

    foreach(lineno, line; [""] ~ content.splitLines())
    {
        //---------------------------------------------------------------------
        // Cut comments and empty lines.
        //---------------------------------------------------------------------

        if(line.indexOf('#') != -1) line.length = line.indexOf('#');
        line = line.strip();
        if(!line.length) continue;

        //---------------------------------------------------------------------
        // Split line to args
        //---------------------------------------------------------------------

        string[] args = line.split();

        //---------------------------------------------------------------------
        // Processing args
        //---------------------------------------------------------------------

        switch(args[0])
        {
            default: throw new Exception(format("%s:%d: Unknown command '%s'", filename, lineno, args[0]));

            // Vertex data (position, UV, normal)

            case "v": v ~= vec3(
                to!float(args[1]),
                to!float(args[2]),
                to!float(args[3])
            ); break;
            case "vt": vt ~= vec2(
                to!float(args[1]),
                to!float(args[2])
            ); break;
            case "vn": vn ~= vec3(
                to!float(args[1]),
                to!float(args[2]),
                to!float(args[3])
            ).normalized(); break;

            // Triangularize faces (assume polygon is convex)

            case "f":
                foreach(i; 3 .. args.length) {
                    f ~= TRIANGLE(args[1], args[i-1], args[i]);
                }
                break;

            // Generated normals: smoothing on/off... Does not work yet.

            case "s":
                smoothing = (args[1] == "on") || (args[1] == "1");
                break;

            // Silently ignored

            case "g":
            case "o":
            case "mtllib":
            case "usemtl": break;
        }
    }

    /*
    writeln("Loaded......: ", filename);
    writeln("- Vertices..: ", v.length);
    writeln("- UV........: ", vt.length);
    writeln("- Normals...: ", vn.length);
    writeln("- Triangles.: ", f.length);
    */

    //-------------------------------------------------------------------------
    // Fill missing UV coordinates
    //-------------------------------------------------------------------------

    vt ~= vec2(0, 0);

    foreach(i, face; f) foreach(j, vertex; face.vertices)
    {
        if(!vertex.vt_ind) f[i].vertices[j].vt_ind = cast(uint)vt.length;
    }

    //-------------------------------------------------------------------------
    // Compute missing normals from surface. TODO: Smoothed normals
    //-------------------------------------------------------------------------

    foreach(i, face; f)
    {
        vec3 a = v[face.vertices[0].v_ind-1] - v[face.vertices[1].v_ind-1];
        vec3 b = v[face.vertices[0].v_ind-1] - v[face.vertices[2].v_ind-1];

        vn ~= a.cross(b).normalized();

        foreach(j, vertex; face.vertices) {
            if(!vertex.vn_ind) f[i].vertices[j].vn_ind = cast(uint)vn.length;
        }
    }

    //-------------------------------------------------------------------------
    //
    // OpenGL vertex attributes are indexed with same index. For this
    // reason, we need to create vertex data for each unique pair of
    // coordinates, normals and UV.
    //
    //-------------------------------------------------------------------------

    Mesh mesh = new Mesh(GL_TRIANGLES);

    ushort[string] indices;

    ushort getindex(VERTEX vertex)
    {
        string key = vertex.key();

        if(!(key in indices))
        {
            indices[key] = mesh.addvertex(
                v[vertex.v_ind - 1],    // Position
                vt[vertex.vt_ind - 1],  // Texture (UV) coordinates
                vn[vertex.vn_ind - 1],  // Vertex normal
            );
        }
        return indices[key];
    }

    foreach(face; f)
    {
        mesh.addface(
            getindex(face.vertices[0]),
            getindex(face.vertices[1]),
            getindex(face.vertices[2])
        );
    }

    /*
    writeln("Mesh:");
    writeln("- VBO length: ", mesh.vertices);
    writeln("- IBO length: ", mesh.faces.length);
    */

    return mesh;
}
