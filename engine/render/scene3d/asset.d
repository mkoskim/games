//*****************************************************************************
//
// Asset loading: What we try to achieve is easy load & unload asset sets,
// for example game levels.
//
//*****************************************************************************

module engine.render.scene3d.asset;

import engine.render.loader.mesh;
import engine.render.scene3d.types.material;
import engine.render.scene3d.types.model;
import engine.render.scene3d.batch;

//*****************************************************************************
//
// Asset management
//
//*****************************************************************************

class Asset
{
    Model[string] models;

    Mesh[string] meshes;
    Material[string] materials;
    Batch.VAO[Mesh] shapes;

    //-------------------------------------------------------------------------

    Material upload(string name, Material material)
    {
        materials[name] = material;
        return material;
    }

    Mesh upload(string name, Mesh mesh)
    {
        meshes[name] = mesh;
        return mesh;
    }

    Batch.VAO upload(Batch target, Mesh mesh) {
        if(mesh !in shapes) shapes[mesh] = target.upload(mesh);
        return shapes[mesh];
    }

    //-------------------------------------------------------------------------

    Model upload(string name, Model model)
    {
        if(name) models[name] = model;
        return model;
    }
    
    Model upload(string name, Batch.VAO vao, Material material)
    {
        return upload(name, new Model(vao, material));
    }

    Model upload(string name, Batch.VAO vao, string material)
    {
        return upload(name, vao, materials[material]);
    }

    Model upload(string name, Batch target, Mesh mesh, Material material)
    {
        return upload(name, upload(target, mesh), material);
    }

    Model upload(string name, Batch target, Mesh mesh, string material)
    {
        return upload(name, upload(target, mesh), materials[material]);
    }

    Model upload(string name, Batch target, string mesh, string material)
    {
        return upload(name, target, meshes[mesh], materials[material]);
    }

    //-------------------------------------------------------------------------

    Model get(string name) { return models[name]; }
    Model opIndex(string name) { return get(name); }
    Model opCall(string name) { return get(name); }
}

class AssetGroup
{
    Asset[string] assets;
    Material.Loader material = new Material.Loader();
    
    Asset add(string name, Asset asset) {
        assets[name] = asset;
        return asset;
    }
    Asset add(string name) { return add(name, new Asset()); }

    Asset get(string name) { return assets[name]; }
    Asset opIndex(string name) { return get(name); }
    Asset opCall(string name) { return get(name); }

    void remove(string name) { assets.remove(name); }
}


