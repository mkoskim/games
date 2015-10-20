//-----------------------------------------------------------------------------
// Material
//-----------------------------------------------------------------------------

struct MAT_MODIFIER
{
    vec4 color;
};

struct MATERIAL
{
    sampler2D colormap;
    sampler2D normalmap;

    float roughness;

    MAT_MODIFIER modifier;
};

//-----------------------------------------------------------------------------
// Light
//-----------------------------------------------------------------------------

struct LIGHT
{
    vec3  color;            // Light color
    vec3  pos;              // Light position
    float radius;           // Linear attenuation factor
    float ambient;          // Ambient lightning factor
};

