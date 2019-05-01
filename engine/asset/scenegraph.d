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

import engine.asset.types.transform;
import engine.asset.plop;
import std.path;

//*****************************************************************************
//
// Design:
//
// Current implementation needs too many temporary buffers. We should be
// able to translate loaded ASSIMP models directly to the desired VBOs. Thus,
// all the post-load processing should be implemented as translation matrix,
// which is applied when VBOs are created:
//
// aiMesh -> analysis & translation matrix -> VBOs
//
//*****************************************************************************


//*****************************************************************************
//
//*****************************************************************************

private string tostr(const aiString str)
{
    return to!string(str.data[0 .. str.length]);
}

//*****************************************************************************
//
// Make a "local" copy of ASSIMP data structures. This allows us to modify
// scene graph later (add and remove objects).
//
//*****************************************************************************

class SceneGraph
{
    //*************************************************************************
    //
    // TODO: Mesh & Node classes should be user-defined. This file could
    // contain abstract class with loading interface, but how data is finally
    // stored to GPU depends on the shaders used by the game.
    //
    //*************************************************************************

    class Mesh
    {
        string name;
        
        vec3[] pos;
        vec2[] uv;
        vec3[] t, b, n;
        //mat3[] tbn;
        
        struct Face {
            ushort a, b, c;
        }
        Face[] triangles;
        
        //---------------------------------------------------------------------

        this(const aiMesh* mesh)
        {
            vec3 tovec3(const aiVector3D v) { return vec3(v.x, v.y, v.z); }
            vec2 tovec2(const aiVector3D v) { return vec2(v.x, 1 - v.y); }
            mat3 tomat3(const aiVector3D a, const aiVector3D b, const aiVector3D c)
            {
                return mat3(tovec3(a), tovec3(b), tovec3(c));
            }
            
            name = tostr(mesh.mName);

            foreach(i; 0 .. mesh.mNumVertices)
            {
                pos ~= tovec3(mesh.mVertices[i]);
                if(mesh.mTextureCoords[0]) uv ~= tovec2(mesh.mTextureCoords[0][i]);
                if(mesh.mNormals && mesh.mTangents) {
                    t ~= tovec3(mesh.mTangents[i]);
                    b ~= tovec3(mesh.mBitangents[i]);
                    n ~= tovec3(mesh.mNormals[i]);
                }
            }
            
            foreach(i; 0 .. mesh.mNumFaces)
            {
                triangles ~= Face(
                    cast(ushort)mesh.mFaces[i].mIndices[0],
                    cast(ushort)mesh.mFaces[i].mIndices[1],
                    cast(ushort)mesh.mFaces[i].mIndices[2]
                );
            }
            
            /*
            foreach(i; 0 .. mesh.mNumBones)
            {
                writeln("- ", tostr(mesh.mBones[i].mName));
            }
            */
        }

        //---------------------------------------------------------------------

        auto AABB() { return AABBT!(float).from_points(pos); }
        auto dim()  {
            auto aabb = AABB();
            return aabb.max - aabb.min;
        }

        void scale(float f)   { foreach(ref v; pos) v *= f; }
        void move(vec3 delta) { foreach(ref v; pos) v += delta; }
        void move(float x, float y, float z) { move(vec3(x, y, z)); }

        //---------------------------------------------------------------------
        // Switch object WHD - Width, Height, Depth - axis if needed.
        //---------------------------------------------------------------------

        void WHD(string[3] game, string[3] object)
        {
            immutable vec3[string] row = [
                "X":  vec3( 1,  0,  0),
                "Y":  vec3( 0,  1,  0),
                "Z":  vec3( 0,  0,  1),
                "-X": vec3(-1,  0,  0),
                "-Y": vec3( 0, -1,  0),
                "-Z": vec3( 0,  0, -1),
            ];
            
            bool handness(string[3] specs)
            {
                return row[specs[0]].cross(row[specs[1]]).dot(row[specs[2]]) > 0;
            }

            vec3 x, y, z;
            //mat3 m;

            foreach(i, gaxis; game)
            {
                auto oaxis = object[i];
                Log << format("%s => %s", gaxis, oaxis);

                final switch(gaxis)
                {
                    case "X": x = row[oaxis]; break;
                    case "Y": y = row[oaxis]; break;
                    case "Z": z = row[oaxis]; break;
                    case "-X": x = -row[oaxis]; break;
                    case "-Y": y = -row[oaxis]; break;
                    case "-Z": z = -row[oaxis]; break;
                }
            }

            mat3 m = mat3(x, y, z);

            foreach(ref v; pos) v = m * v;
            foreach(ref v; t) v = m * v;
            foreach(ref v; b) v = m * v;
            foreach(ref v; n) v = m * v;

            if(handness(object) != handness(game)) foreach(ref face; triangles)
            {
                auto t = face.b;
                face.b = face.c;
                face.c = t;
            }
        }
    }

    //*************************************************************************
    //*************************************************************************

    //-------------------------------------------------------------------------

    Mesh[int] meshes;
    
    void loadMeshes(const aiScene* scene)
    {
        foreach(i; 0 .. scene.mNumMeshes)
        {
            auto mesh = new Mesh(scene.mMeshes[i]);
            
            meshes[i] = mesh;
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

    //-------------------------------------------------------------------------

    this(const aiScene* scene)
    {
        loadMeshes(scene);
        root = loadNode(null, scene.mRootNode);
    }

    //-------------------------------------------------------------------------

    enum Option {
        FlipUV,
        CombineMeshes,
    };

    static SceneGraph load(string filename, Option[] options...)
    {
        aiPostProcessSteps postprocess = 
            aiProcess_Triangulate |
            //aiProcess_GenNormals |
            aiProcess_GenSmoothNormals |
            aiProcess_CalcTangentSpace |
            //aiProcess_MakeLeftHanded |
            //aiProcess_FlipUVs |
            aiProcess_JoinIdenticalVertices |
            aiProcess_ImproveCacheLocality |
            aiProcess_OptimizeMeshes;

        foreach(option; options) final switch(option)
        {
            case SceneGraph.Option.FlipUV: postprocess |= aiProcess_FlipUVs; break;
            case SceneGraph.Option.CombineMeshes: postprocess |= aiProcess_OptimizeGraph; break;
        }

        auto buffer = vfs.extract(filename);

        auto loaded = aiImportFileFromMemory(
            buffer.ptr,
            cast(uint)buffer.length,
            postprocess,
            toStringz(std.path.extension(filename))
        ); 

        ERRORIF(!loaded, to!string(aiGetErrorString()));

        auto scene = new SceneGraph(loaded);

        aiReleaseImport(loaded);

        return scene;
    }
}

