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
// I really need to think this. Although making (temporal) copies of ASSIMP
// objects does not sound sensible, it has its own strengths. With this, we can
// discard memory allocated by ASSIMP early, leaving less room for errors. It
// also greatly simplifies post-processing, before they are used to create
// buffers for GPU.
//
// Basically, the only real drawback is if you need just one or two assets
// from large file. We could argue, that it would then better extract those
// few assets from that mega file... In every case, the most probable use cases
// for this asset loader are:
//
// - Loading single assets from 3D files containing only that single asset:
//   this would mean loading lots of small files.
//
// - When loading a large file, most probably that file is tailored for the
//   game and you need most of its content.
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

engine.asset.Material.Loader loadmaterial;

static this()
{
    loadmaterial = new engine.asset.Material.Loader();
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

    mat3 mGameSpace;        // Matrix to rotate objects to "game space"
    Mesh[int] meshes;
    
    this(const aiScene* scene, mat3 sWHD)
    {
        this.mGameSpace = gWHD * sWHD;
        
        if(!handness(mGameSpace))
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
            
            name = tostr(mesh.mName);
            pos  = tovec3(mesh.mNumVertices, mesh.mVertices, mGameSpace);
            t    = tovec3(mesh.mNumVertices, mesh.mTangents, mGameSpace);
            b    = tovec3(mesh.mNumVertices, mesh.mBitangents, mGameSpace);
            n    = tovec3(mesh.mNumVertices, mesh.mNormals, mGameSpace);
            uv   = tovec2(mesh.mNumVertices, mesh.mTextureCoords[0]);

            for(int i = 0; i < mesh.mNumFaces; i++) faces ~= Face(mesh.mFaces[i]);
        }

        //---------------------------------------------------------------------
        // Adjust scale & reference point
        //---------------------------------------------------------------------

        void postprocess(vec3 refpoint, vec3 saxis, float scale)
        {
            auto AABB() { return AABBT!(float).from_points(pos); }
            auto dim(AABBT!(float) aabb)  { return aabb.max - aabb.min; }

            //-----------------------------------------------------------------
            // Move reference point to given point and scale the mesh
            //-----------------------------------------------------------------
            
            //Log << format("Dim(initial): %s", to!string(dim(AABB())));

            auto bb = AABB();
            auto d  = dim(bb);

            float s = scale / (d * saxis);

            auto rp_now = (bb.min + bb.max) / 2;
            auto rp_desired = bb.min + vec3(
                rp_now.x + d.x * refpoint.x,
                rp_now.y + d.y * refpoint.y,
                rp_now.z + d.z * refpoint.z
            );

            auto delta = rp_desired - rp_now;
            foreach(ref v; pos) v = (v - delta) * s;

            //Log << format("Dim(scaled): %s", to!string(dim(AABB())));
            /*
            {
                auto bb = AABB();
                Log << format("AABB (%f - %f), (%f - %f), (%f - %f)",
                    bb.min.x, bb.max.x,
                    bb.min.y, bb.max.y,
                    bb.min.z, bb.max.z
                );
            } */
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
