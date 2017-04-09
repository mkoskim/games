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
import blob = engine.asset.blob;
import derelict.assimp3.assimp;

import engine.asset.types.transform;
import std.path;

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
    //*************************************************************************

    class Mesh
    {
        string name;
        
        vec3[] pos;
        vec2[] uv;
        vec3[] t;
        vec3[] b;
        vec3[] n;
        
        ushort[] triangles;
        
        //---------------------------------------------------------------------

        this(const aiMesh* mesh)
        {
            vec3 tovec3(const aiVector3D v) { return vec3(v.x, v.y, v.z); }
            vec2 tovec2(const aiVector3D v) { return vec2(v.x, v.y); }
            mat3 tomat3(const aiVector3D a, const aiVector3D b, const aiVector3D c)
            {
                return mat3(tovec3(a), tovec3(b), tovec3(c));
            }
            
            name = tostr(mesh.mName);
            //writefln("Mesh: %s", name);
            //writeln("- Vertices: ", mesh.mNumVertices);
            
            foreach(i; 0 .. mesh.mNumVertices)
            {
                pos ~= tovec3(mesh.mVertices[i]);
                if(mesh.mTextureCoords[0]) uv ~= tovec2(mesh.mTextureCoords[0][i]);
                if(mesh.mTangents) {
                    t ~= tovec3(mesh.mTangents[i]);
                    b ~= tovec3(mesh.mBitangents[i]);
                    n ~= tovec3(mesh.mNormals[i]);
                }
                //writeln("P: ", pos[i], "uv: ", uv[i]);
            }
            
            foreach(i; 0 .. mesh.mNumFaces)
            {
                triangles ~= [
                    cast(ushort)mesh.mFaces[i].mIndices[0],
                    cast(ushort)mesh.mFaces[i].mIndices[1],
                    cast(ushort)mesh.mFaces[i].mIndices[2]
                ];
            }
        }
    }

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
            writeln("Node: ", name);
            foreach(i; 0 .. node.mNumMeshes)
            {
                meshes ~= node.mMeshes[i];
                writeln("- Mesh: ", node.mMeshes[i]);
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

    //-------------------------------------------------------------------------

    this(const aiScene* scene)
    {
    /*
        writeln("Animations: ", scene.mNumAnimations);
        writeln("Cameras...: ", scene.mNumCameras);
        writeln("Lights....: ", scene.mNumLights);
        writeln("Textures..: ", scene.mNumTextures);
        writeln("Materials.: ", scene.mNumMaterials);
        writeln("Meshes....: ", scene.mNumMeshes);
    */
        loadMeshes(scene);
        root = loadNode(null, scene.mRootNode);
    }

    //-------------------------------------------------------------------------

    static SceneGraph load(string filename)
    {
        auto buffer = blob.extract(filename);

        auto loaded = aiImportFileFromMemory(
            buffer.ptr,
            cast(uint)buffer.length,
                aiProcess_Triangulate |
                aiProcess_GenNormals |
                aiProcess_CalcTangentSpace |
                //aiProcess_SortByPType |
                aiProcess_ImproveCacheLocality |
                aiProcess_JoinIdenticalVertices |
                aiProcess_OptimizeMeshes |
                //aiProcess_OptimizeGraph |
                0,
            toStringz(std.path.extension(filename))
        ); 

        if(!loaded)
        {
            writeln("Error: ", to!string(aiGetErrorString()));
            return null;
        }

        auto scene = new SceneGraph(loaded);

        aiReleaseImport(loaded);

        return scene;
    }
}

