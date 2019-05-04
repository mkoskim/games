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
// Loading color and normal maps
//*****************************************************************************

engine.asset.Material.Loader loadmaterial;

static this()
{
    loadmaterial = new engine.asset.Material.Loader();
}

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

bool handness(vec3 a, vec3 b, vec3 c) { return a.cross(b).dot(c) > 0; }
bool handness(mat3 m) { return handness(vec3(m[0]), vec3(m[1]), vec3(m[2])); }
bool handness(mat4 m) { return handness(mat3(m)); }

//*****************************************************************************
//
// Specify coordinate system telling which axes specify Width, Height and
// Depth.
//
//*****************************************************************************

enum Plane {
    XY,         // X grows right, Y grows forward, Z grows up
    XZ,         // X grows right, Y grows up, Z grows backwards
    XYF,        // For models only: XY plane, object looking forward
    XZF,        // For models only: XZ plane, object looking forward
}

Plane gPlane;  // Game-wise coordinate system

private mat3 mPlane(Plane s, Plane t)
{
    //Log << format("%s -> %s", to!string(s), to!string(t));

    final switch(t)
    {
        case Plane.XY: final switch(s)
        {
            case Plane.XY:  return mat3.identity();
            case Plane.XYF: return mat3.identity().rotatez(PI);
            case Plane.XZ:  return mat3.identity().rotatex(PI_2);
            case Plane.XZF: return mat3.identity().rotatex(PI_2).rotatez(PI);
        }

        case Plane.XZ: final switch(s)
        {
            case Plane.XZ:  return mat3.identity();
            case Plane.XZF: return mat3.identity().rotatey(PI);
            case Plane.XY:  return mat3.identity().rotatex(-PI_2);
            case Plane.XYF: return mat3.identity().rotatez(PI).rotatex(-PI_2);
        }

        case Plane.XYF:
        case Plane.XZF: break;
    }

    ERROR(format("Invalid planes: %s -> %s", to!string(s), to!string(t)));
    assert(0);
}

//*****************************************************************************
//
// Abstract class to help manipulating ASSIMP objects
//
//*****************************************************************************

abstract class aiObject
{
    vec3 tovec3(const aiVector3D v) { return vec3(v.x, v.y, v.z); }
    vec2 tovec2(const aiVector3D v) { return vec2(v.x, v.y); }
    vec2 tovec2(const aiVector2D v) { return vec2(v.x, v.y); }

    auto AABB(uint count, const aiVector3D* v)
    {
        AABBT!(float) aabb;
        for(int i = 0; i < count; i++) aabb.expand(tovec3(v[i]));
        return aabb;
    }

    auto dim(AABBT!(float) aabb)  { return aabb.max - aabb.min; }
}

//*****************************************************************************
//
// Load scene
//
//*****************************************************************************

class Scene : aiObject
{
    mat3 mGameSpace;        // Matrix to rotate objects to "game space"
    const aiScene* scene;   // Loaded scene
    
    //-------------------------------------------------------------------------

    enum Flag {
        FlipUV,
        CombineMeshes,
    };

    this(string filename, Plane sPlane, Flag[] flags...)
    {
        Track.add(this);

        auto getoptions()
        {
            aiPostProcessSteps postprocess = 
                //aiProcess_MakeLeftHanded |
                aiProcess_Triangulate |
                //aiProcess_GenNormals |
                //aiProcess_GenSmoothNormals |
                aiProcess_CalcTangentSpace |
                aiProcess_JoinIdenticalVertices |
                aiProcess_ImproveCacheLocality |
                aiProcess_OptimizeMeshes;

            foreach(flag; flags) final switch(flag)
            {
                case Flag.FlipUV: postprocess |= aiProcess_FlipUVs; break;
                case Flag.CombineMeshes: postprocess |= aiProcess_OptimizeGraph; break;
            }
            
            return postprocess;
        }
        
        mGameSpace = mPlane(sPlane, gPlane);
        
        //Log << to!string(mGameSpace);
        
        auto buffer = vfs.extract(filename);
        
        scene = aiImportFileFromMemory(
            buffer.ptr,
            cast(uint)buffer.length,
            getoptions(),
            toStringz(std.path.extension(filename))
        ); 

        ERRORIF(!scene, to!string(aiGetErrorString()));        
    }

    ~this()
    {
        Track.remove(this);
        aiReleaseImport(scene);
    }
}

//*****************************************************************************
//
// Abstract class to help creating GPU buffers
//
//*****************************************************************************

abstract class Mesh : aiObject
{
    const aiMesh* mesh;
    
    mat3 mGameSpace;
    mat4 mPostProcess;
        
    this(const aiMesh* mesh, mat3 mGameSpace, vec3 refpoint, vec3 saxis, float scale)
    {
        this.mesh = mesh;
        this.mGameSpace = mGameSpace;

        auto bb = AABB(mesh.mNumVertices, mesh.mVertices);
        bb.min  = mGameSpace * bb.min;
        bb.max  = mGameSpace * bb.max;
        auto d  = bb.extent();
        
        auto rp = refpoint;
        auto delta = -vec3(d.x * rp.x, d.y * rp.y, d.z * rp.z) - bb.min;

        float s = scale / (saxis * d);

        mPostProcess = mat4.identity()
            .translate(delta)
            .scale(s, s, s)
        ;
    }
}



