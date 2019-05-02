//*****************************************************************************
//*****************************************************************************
//
// Model loading with ASSIMP. This needs to be thought clearly. We might want
// just models from some files, and full scene graphs from others.
//
//*****************************************************************************
//*****************************************************************************

module engine.asset.scenegraph;

//-----------------------------------------------------------------------------

import engine.asset.util;
import derelict.assimp3.assimp;
import engine.gpu.texture;

import engine.asset.types.transform;
import std.path;

//*****************************************************************************
//
// Design:
//
// I really need to rethink this. It is not necessarily a bad idea to first
// make "D copies" from ASSIMP objects, and release all memory allocated by
// ASSIMP. Then, we could post-process those D objects, before creating buffers
// for GPU.
//
// TODO: Lets try now make this implementation to use matrix transformation
// operations for Mesh, nothing else. We may be able to use them to assimp
// data, too.
//
//*****************************************************************************

enum Option {
    FlipUV,
    CombineMeshes,
};

//-------------------------------------------------------------------------

auto load(string filename, string[3] sWHD, Option[] options...)
{
    aiPostProcessSteps postprocess = 
        aiProcess_Triangulate |
        //aiProcess_GenNormals |
        aiProcess_GenSmoothNormals |
        aiProcess_CalcTangentSpace |
        aiProcess_JoinIdenticalVertices |
        aiProcess_ImproveCacheLocality |
        aiProcess_OptimizeMeshes;

    foreach(option; options) final switch(option)
    {
        case Option.FlipUV: postprocess |= aiProcess_FlipUVs; break;
        case Option.CombineMeshes: postprocess |= aiProcess_OptimizeGraph; break;
    }

    auto buffer = vfs.extract(filename);

    auto loaded = aiImportFileFromMemory(
        buffer.ptr,
        cast(uint)buffer.length,
        postprocess,
        toStringz(std.path.extension(filename))
    ); 

    ERRORIF(!loaded, to!string(aiGetErrorString()));

    auto scene = new SceneGraph(loaded, sWHD);

    aiReleaseImport(loaded);

    return scene;
}

auto loadmesh(string filename, string[3] sWHD, Option[] options...)
{
    auto scene = load(filename, sWHD, options);
    return scene.meshes[0];
}

//*****************************************************************************
// Loading color and normal maps
//*****************************************************************************

engine.gpu.Texture.Loader loadcolormap;
engine.gpu.Texture.Loader loadnormalmap;

static this()
{
    loadcolormap = engine.gpu.Texture.Loader.Compressed;
    loadnormalmap = engine.gpu.Texture.Loader.Default;
}

//*****************************************************************************
//
// Make a "local" copy of ASSIMP data structures. This allows us to modify
// scene graph later (add and remove objects).
//
//*****************************************************************************

class SceneGraph
{
    //-------------------------------------------------------------------------
    // Specify coordinate system telling which axes specify Width, Height and
    // Depth.
    //-------------------------------------------------------------------------
    
    static mat3 gWHD;  // Game-wise coordinate system
    mat3 sWHD;         // Scene-specific coordinate system

    static mat3 WHD(string W, string H, string D)
    {
        const vec3[string] row = [
            "X":  vec3( 1,  0,  0),
            "Y":  vec3( 0,  1,  0),
            "Z":  vec3( 0,  0,  1),
            "-X": vec3(-1,  0,  0),
            "-Y": vec3( 0, -1,  0),
            "-Z": vec3( 0,  0, -1),
        ];

        return mat3(vec3(row[W]), vec3(row[H]), vec3(row[D]));
    }
    static mat3 WHD(string[3] whd)
    {
        return WHD(whd[0], whd[1], whd[2]);
    }
        
    static bool handness(vec3 a, vec3 b, vec3 c) { return a.cross(b).dot(c) > 0; }
    static bool handness(mat3 m) { return handness(vec3(m[0]), vec3(m[1]), vec3(m[2])); }

    //-------------------------------------------------------------------------

    Mesh[int] meshes;
    
    this(const aiScene* scene, mat3 sWHD)
    {
        this.sWHD = sWHD;
        
        if(handness(gWHD) != handness(sWHD))
        {
            aiApplyPostProcessing(scene, aiProcess_FlipWindingOrder);
        }
        
        foreach(i; 0 .. scene.mNumMeshes)
        {
            meshes[i] = new Mesh(scene.mMeshes[i]);
        }
    }

    this(const aiScene* scene, string[3] sWHD)
    {
        this(scene, WHD(sWHD));
    }


    //*************************************************************************
    // Creating copies of buffers
    //*************************************************************************

    private string tostr(const aiString str)
    {
        return to!string(str.data[0 .. str.length]);
    }

    private vec3[] tovec3(const uint num, const aiVector3D* vec)
    {
        vec3[] result;
        for(int i = 0; i < num; i++) result ~= vec3(vec[i].x, vec[i].y, vec[i].z);
        return result;
    }

    private vec3[] tovec3(const uint num, const aiVector3D* vec, const mat3 m)
    {
        vec3[] result;
        for(int i = 0; i < num; i++) result ~= m * vec3(vec[i].x, vec[i].y, vec[i].z);
        return result;
    }

    private vec2[] tovec2(const uint num, const aiVector3D* vec)
    {
        vec2[] result;
        for(int i = 0; i < num; i++) result ~= vec2(vec[i].x, vec[i].y);
        return result;
    }

    //*************************************************************************
    //
    // Temporary Mesh object for processing
    //
    //*************************************************************************

    class Mesh
    {
        string name;
        
        vec3[] pos;
        vec2[] uv;
        vec3[] t, b, n;
        
        Face[] faces;
                        
        //---------------------------------------------------------------------

        struct Face {
            ushort a, b, c;
            this(const aiFace face)
            {
                assert(face.mNumIndices == 3);
                a = cast(ushort)face.mIndices[0];
                b = cast(ushort)face.mIndices[1];
                c = cast(ushort)face.mIndices[2];
            }
        }

        //---------------------------------------------------------------------
        // Make a copy from ASSIMP mesh
        //---------------------------------------------------------------------
        
        this(const aiMesh* mesh)
        {
            //-----------------------------------------------------------------
            // Switch mesh coordinate system to game coordinate system
            //-----------------------------------------------------------------
            
            mat3 m = gWHD * sWHD;

            name = tostr(mesh.mName);
            pos  = tovec3(mesh.mNumVertices, mesh.mVertices, m);
            t    = tovec3(mesh.mNumVertices, mesh.mTangents, m);
            b    = tovec3(mesh.mNumVertices, mesh.mBitangents, m);
            n    = tovec3(mesh.mNumVertices, mesh.mNormals, m);
            uv   = tovec2(mesh.mNumVertices, mesh.mTextureCoords[0]);

            for(int i = 0; i < mesh.mNumFaces; i++) faces ~= Face(mesh.mFaces[i]);
        }

        //---------------------------------------------------------------------
        // Switch object WHD - Width, Height, Depth - axis if needed.
        //---------------------------------------------------------------------

        void postprocess(vec3 refpoint, vec3 saxis, float scale)
        {
            auto AABB() { return AABBT!(float).from_points(pos); }
            auto dim(AABBT!(float) aabb)  { return aabb.max - aabb.min; }

            //-----------------------------------------------------------------
            // Move reference point to given point
            //-----------------------------------------------------------------
            
            {
                auto bb = AABB();
                auto d  = dim(bb);
                
                auto cnow = (bb.min + bb.max) / 2;                
                auto cdesired = bb.min + vec3(
                    cnow.x + d.x * refpoint.x,
                    cnow.y + d.y * refpoint.y,
                    cnow.z + d.z * refpoint.z
                );

                Log << format("Refpoint........: %s", to!string(refpoint));
                Log << format("Center (now)....: %s", to!string(cnow));
                Log << format("Center (desired): %s", to!string(cdesired));
                
                auto delta = cdesired - cnow;
                foreach(ref v; pos) v -= delta;
            }
            
            //-----------------------------------------------------------------
            // Scale mesh to given size
            //-----------------------------------------------------------------
            
            Log << format("Dim(initial): %s", to!string(dim(AABB())));
            
            {
                float s = scale / (dim(AABB()) * saxis);
            
                foreach(ref v; pos) v *= s;
            }
            
            Log << format("Dim(scaled): %s", to!string(dim(AABB())));
            
            //-----------------------------------------------------------------
            // Show results
            //-----------------------------------------------------------------
            
            {
                auto bb = AABB();
                Log << format("AABB (%f - %f), (%f - %f), (%f - %f)",
                    bb.min.x, bb.max.x,
                    bb.min.y, bb.max.y,
                    bb.min.z, bb.max.z
                );
            }
        }
    }

    //*************************************************************************
    //*************************************************************************

    class Node
    {
        string name;

        Node parent;
        Node[] children;

        Transform transform;
        int[] meshes;

        this(Node parent, const aiNode *node)
        {
            this.parent = parent;
            name = tostr(node.mName);
            //writeln("Node: ", name);
            foreach(i; 0 .. node.mNumMeshes)
            {
                meshes ~= node.mMeshes[i];
                //writeln("- Mesh: ", node.mMeshes[i]);
            }
        }
    }

    //-------------------------------------------------------------------------

    Node root;
    Node[string] lookup;

    Node loadNode(Node parent, const aiNode *loaded)
    {
        auto node = new Node(parent, loaded);

        if(node.name) lookup[node.name] = node;
        
        foreach(i; 0 .. loaded.mNumChildren)
        {
            node.children ~= loadNode(node, loaded.mChildren[i]);
        }
        return node;
    }

    void info()
    {
        Log("Loader")
            << format("Meshes: %d", meshes.length)
        ;

        foreach(i, mesh; meshes)
        {
            Log("Loader") << format("- Mesh %d: %s", i, mesh.name);
        }
    }
}

