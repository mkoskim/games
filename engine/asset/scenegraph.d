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
        vec3[] t;
        vec3[] b;
        vec3[] n;
        
        ushort[] triangles;
        
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

            /*
            writefln("Mesh: %s", name);
            writeln("- Vertices: ", mesh.mNumVertices);
            writeln("- Faces...: ", mesh.mNumFaces);
            writeln("- Bones...: ", mesh.mNumBones);
            */
            foreach(i; 0 .. mesh.mNumVertices)
            {
                pos ~= tovec3(mesh.mVertices[i]);
                if(mesh.mTextureCoords[0]) uv ~= tovec2(mesh.mTextureCoords[0][i]);
                if(mesh.mNormals) {
                    n ~= tovec3(mesh.mNormals[i]);
                }
                if(mesh.mTangents) {
                    t ~= tovec3(mesh.mTangents[i]);
                    b ~= tovec3(mesh.mBitangents[i]);
                }
                //writeln("P=", pos[i], "n=", n[i]);
            }
            
            foreach(i; 0 .. mesh.mNumFaces)
            {
                triangles ~= [
                    cast(ushort)mesh.mFaces[i].mIndices[0],
                    cast(ushort)mesh.mFaces[i].mIndices[1],
                    cast(ushort)mesh.mFaces[i].mIndices[2]
                ];
            }
            
            /*
            foreach(i; 0 .. mesh.mNumBones)
            {
                writeln("- ", tostr(mesh.mBones[i].mName));
            }
            */
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

    //-------------------------------------------------------------------------

    this(const aiScene* scene)
    {
    /*
        writeln("Root........: ", tostr(scene.mRootNode.mName));
        writeln("- Meshes....: ", scene.mNumMeshes);
        writeln("- Textures..: ", scene.mNumTextures);
        writeln("- Materials.: ", scene.mNumMaterials);
        writeln("- Animations: ", scene.mNumAnimations);
        writeln("- Lights....: ", scene.mNumLights);
        writeln("- Cameras...: ", scene.mNumCameras);
    /**/
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
        auto buffer = vfs.extract(filename);

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

        auto loaded = aiImportFileFromMemory(
            buffer.ptr,
            cast(uint)buffer.length,
            postprocess,
            toStringz(std.path.extension(filename))
        ); 

        if(!loaded)
        {
            //writeln("Error: ", to!string(aiGetErrorString()));
            return null;
        }

        auto scene = new SceneGraph(loaded);

        aiReleaseImport(loaded);

        return scene;
    }
}

