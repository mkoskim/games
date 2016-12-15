//*****************************************************************************
//*****************************************************************************
//
// Preliminary: Model loading with ASSIMP. This needs to be thought
// clearly. We might want just models from some files, and full scene graphs
// from others.
//
//*****************************************************************************
//*****************************************************************************

module engine.asset.scenegraph;

//-----------------------------------------------------------------------------

import engine.asset.util;
import derelict.assimp3.assimp;

//-----------------------------------------------------------------------------

string tostr(aiString str)
{
    return to!string(str.data[0 .. str.length]);
}

//-----------------------------------------------------------------------------

void processNode(const aiNode* node, const aiScene* scene)
{
    static string prefix = "";
    
    writeln(prefix, "Processing: ", tostr(node.mName));
    
    // Process all the node's meshes (if any)
    foreach(i; 0 .. node.mNumMeshes)
    {
        auto mesh = scene.mMeshes[node.mMeshes[i]]; 
        writeln(prefix, "- Mesh: ", tostr(mesh.mName));
        writeln(prefix, "- Vertices:", mesh.mNumFaces);
        writeln(prefix, "- Faces:", mesh.mNumFaces);
        writeln(prefix, "- Bones:", mesh.mNumBones);
        writeln(prefix, "- Anim meshes:", mesh.mNumAnimMeshes);

        foreach(j; 0 .. mesh.mNumBones) {
            writeln(prefix, "- - Bone: ", j);
        }
        
        //this.meshes.push_back(processMesh(mesh, scene));
    }

    prefix ~= "    ";
    
    // Then do the same for each of its children
    foreach(i; 0 .. node.mNumChildren)
    {
        processNode(node.mChildren[i], scene);
    }
    
    prefix.length -= 4;
}  

//-----------------------------------------------------------------------------

void load(string filename)
{
    const aiScene* scene = aiImportFile(
        std.string.toStringz(filename),
        aiProcess_Triangulate |
        aiProcess_SortByPType |
        //aiProcess_JoinIdenticalVertices |
        //aiProcess_OptimizeMeshes |
        //aiProcess_OptimizeGraph |
        0
    ); 

    if(!scene)
    {
        writeln("Error: ", to!string(aiGetErrorString()));
        return;
    }

    processNode(scene.mRootNode, scene);

    aiReleaseImport(scene);
}

