//-----------------------------------------------------------------------------
// Material
//-----------------------------------------------------------------------------

struct MATERIAL
{
	vec4 color;
	sampler2D colormap;
	sampler2D normalmap;

	float roughness;
};

//-----------------------------------------------------------------------------
// Light
//-----------------------------------------------------------------------------

struct LIGHT
{
	vec3  color;			// Light color
	vec3  pos;				// Light position
	float radius;			// Linear attenuation factor
	float ambient;			// Ambient lightning factor
};

