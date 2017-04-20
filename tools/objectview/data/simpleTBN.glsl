//*****************************************************************************
//
// Simple GLSL shader
//
//*****************************************************************************

#extension GL_ARB_shader_image_load_store: require

//-----------------------------------------------------------------------------

#ifdef VERTEX_SHADER
attribute vec3 vert_pos;
attribute vec2 vert_uv;
attribute vec3 vert_T;
attribute vec3 vert_N;
#endif

struct FragInput
{
    vec2 uv;
    mat3 TBN;

    vec3 light_dir;    // Light relative to fragment
    vec3 view_dir;     // Viewer relative to fragment
};

//-----------------------------------------------------------------------------
// Vertex data format
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Frame wide settings
//-----------------------------------------------------------------------------

uniform mat4 mProjection;
uniform mat4 mView;

//-----------------------------------------------------------------------------
// Object wide settings
//-----------------------------------------------------------------------------

uniform mat4 mModel;

struct MATERIAL
{
    sampler2D colormap;
    sampler2D normalmap;
};

uniform MATERIAL material;

//-----------------------------------------------------------------------------

struct LIGHT
{
    vec3 pos;
};

uniform LIGHT light;

//-----------------------------------------------------------------------------

//*****************************************************************************
//
#ifdef VERTEX_SHADER
//
//*****************************************************************************

out FragInput frag;

mat3 compute_TBN(mat4 mCamSpace, vec3 normal, vec3 tangent)
{
    mat3 m = mat3(mCamSpace);
    vec3 n = normal;
    vec3 t = tangent;
    vec3 b = cross(normal, tangent);

    return m * mat3(t, b, n);
}

void main()
{
    mat4 mCamSpace = mView * mModel;

    vec3 frag_pos = (mCamSpace * vec4(vert_pos, 1)).xyz;
    gl_Position = mProjection * vec4(frag_pos, 1);

    frag.uv  = vert_uv;
    frag.TBN = compute_TBN(mCamSpace, vert_N, vert_T);
    frag.light_dir = normalize(light.pos - frag_pos);
    frag.view_dir  = normalize(-frag_pos);
}
#endif

//*****************************************************************************
//
#ifdef FRAGMENT_SHADER
//
//*****************************************************************************

layout(early_fragment_tests) in;

in FragInput frag;

float Lambert_diffuse(vec3 n, vec3 v, vec3 l)
{
    return max(0.0, dot(n, l));
}

float Phong_specular(vec3 n, vec3 v, vec3 l)
{
    float shininess = 10;
    vec3  r = normalize(reflect(-l, n));
    return pow(max(0, dot(r, v)), 0.3*shininess);
}

void main(void)
{
    vec4 texel = texture2D(material.colormap, frag.uv);

    vec3 n = texture2D(material.normalmap, frag.uv).rgb*2.0 - 1.0;
    n = frag.TBN * n;

    vec3 v = frag.view_dir;
    vec3 l = frag.light_dir; 

    float lighting = 
        Lambert_diffuse(n, v, l) +
        Phong_specular(n, v, l) +
        0.25
    ;
    
    texel.rgb = lighting * texel.rgb;

    gl_FragColor = texel;
    //gl_FragColor = vec4(n, 1);
    //gl_FragColor = vec4(1, 0, 0, 1);
}
#endif
