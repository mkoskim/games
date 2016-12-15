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

//*****************************************************************************
//
//*****************************************************************************

private string tostr(const aiString str)
{
    return to!string(str.data[0 .. str.length]);
}

private vec3 tovec3(const aiVector3D vec)
{
    return vec3(vec.x, vec.y, vec.z);
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
        
        //---------------------------------------------------------------------
        struct Vertex
        {
            vec3 pos;
            vec3 uv;
            vec3 normal;
            vec3 tangent;
            
            //this(vec3 pos, vec3 uv, vec3 normal, vec3 tangent)
            this(vec3 pos, vec3 normal, vec3 tangent, vec3 uv)
            {
                this.pos = pos;
                this.normal = normal;
                this.tangent = tangent;
                this.uv = uv;
                
                writefln("  - Vertex: (%.0f, %.0f, %.0f)", pos.x, pos.y, pos.z);
            }
        }

        Vertex[int] vertices;

        //---------------------------------------------------------------------

        struct Triangle {
            int a, b, c;
            
            this(const aiFace face)
            {
                a = face.mIndices[0];
                b = face.mIndices[1];
                c = face.mIndices[2];
                writefln("  - Face: %d - %d - %d", a, b, c);
            }
        }
        Triangle[] faces;

        //---------------------------------------------------------------------

        this(const aiMesh* mesh)
        {
            name = tostr(mesh.mName);
            writefln("Mesh: %s", name);
            writeln("- Vertices: ", mesh.mNumVertices);
            
            foreach(i; 0 .. mesh.mNumVertices)
            {
                vertices[i] = Vertex(
                    tovec3(mesh.mVertices[i]),
                    tovec3(mesh.mNormals[i]),
                    mesh.mTangents ? tovec3(mesh.mTangents[i]) : vec3(0, 0, 0),
                    mesh.mTextureCoords[0] ? tovec3(mesh.mTextureCoords[0][i]) : vec3(),
                );
            }
            
            writeln("- Faces: ", mesh.mNumFaces);
            foreach(i; 0 .. mesh.mNumFaces)
            {
                faces ~= Triangle(mesh.mFaces[i]);
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
        writeln("Animations: ", scene.mNumAnimations);
        writeln("Cameras...: ", scene.mNumCameras);
        writeln("Lights....: ", scene.mNumLights);
        writeln("Textures..: ", scene.mNumTextures);
        writeln("Materials.: ", scene.mNumMaterials);
        writeln("Meshes....: ", scene.mNumMeshes);

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

