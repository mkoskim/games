//*****************************************************************************
//
// Default 3D shader family inputs from CPU
//
//*****************************************************************************

uniform mat4 mProjection;
uniform mat4 mModelView;

#ifdef VERTEX_SHADER
attribute vec3 vert_pos;
attribute vec2 vert_uv;
attribute vec4 vert_norm;
attribute vec4 vert_tangent;
#endif

uniform LIGHT light;
uniform MATERIAL material;

//-----------------------------------------------------------------------------

varying vec2 frag_uv;       // Fragment texture coordinates
varying vec3 frag_pos;      // Fragment position (view space)
varying mat3 frag_TBN;      // Fragment tangent space

varying vec3 frag_light_pos;            // Light direction in tangent space
varying float frag_light_strength;      // Computed intensity

//-----------------------------------------------------------------------------
// Runtime configurations
//-----------------------------------------------------------------------------

uniform bool useNormalMapping = true;
uniform int  useQuants = 0;

