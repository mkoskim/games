//*****************************************************************************
//
// Simple GLSL shader
//
//*****************************************************************************

#extension GL_ARB_shader_image_load_store: require

//-----------------------------------------------------------------------------

struct VertInput
{
    vec3 pos;
    vec2 uv;
    vec3 T;
    vec3 B;
    vec3 N;
};

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

//*****************************************************************************
//*****************************************************************************

struct FragInput
{
    vec2 uv;

    vec3 light_dir;    // Light relative to fragment
    vec3 view_dir;     // Viewer relative to fragment
};

//*****************************************************************************
//
#ifdef VERTEX_SHADER
//
//*****************************************************************************

in  VertInput vert;
out FragInput frag;

mat3 compute_TBN(mat4 mCamSpace, vec3 tangent, vec3 bitangent, vec3 normal)
{
    mat3 m = mat3(mCamSpace);
    vec3 n = normal;
    vec3 t = tangent;
    vec3 b = bitangent; //cross(normal, tangent);

    return m * mat3(t, b, n);
}

void main()
{
    mat4 mCamSpace = mView * mModel;

    vec3 frag_pos  = (mCamSpace * vec4(vert.pos, 1)).xyz;
    vec3 light_pos = (mView * vec4(light.pos, 1)).xyz;
    gl_Position = mProjection * vec4(frag_pos, 1);

    frag.uv  = vert.uv;
    mat3 TBN = transpose(compute_TBN(mCamSpace, vert.T, vert.B, vert.N));
    frag.light_dir = TBN * normalize(light_pos - frag_pos);
    frag.view_dir  = TBN * normalize(-frag_pos);
}
#endif

//*****************************************************************************
//
#ifdef FRAGMENT_SHADER
//
//*****************************************************************************

layout(early_fragment_tests) in;

in  FragInput frag;
out vec4 frag_color;

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

    vec3 n = texture2D(material.normalmap, frag.uv).rgb * 2.0 - 1.0;
    vec3 v = frag.view_dir;
    vec3 l = frag.light_dir; 

    float lighting = 
        Lambert_diffuse(n, v, l) +
        //Phong_specular(n, v, l) +
        0.25
    ;
    
    texel.rgb = lighting * texel.rgb;

    frag_color =
        texel
        //vec4(n*0.5 + 0.5, 1)
        //vec4(1, 0, 0, 1)
    ;
}
#endif
