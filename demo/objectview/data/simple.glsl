uniform mat4 mProjection;
uniform mat4 mView;
uniform mat4 mModel;

//-----------------------------------------------------------------------------

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

#ifdef VERTEX_SHADER
attribute vec3 vert_pos;
attribute vec2 vert_uv;

attribute vec3 vert_T;
attribute vec3 vert_B;
attribute vec3 vert_N;
#endif

//-----------------------------------------------------------------------------

varying vec3 frag_pos;      // Fragment @ view space
varying vec2 frag_uv;
varying mat3 frag_TBN;
varying vec3 frag_light_pos;

//*****************************************************************************
#ifdef VERTEX_SHADER
//*****************************************************************************

mat3 compute_TBN(vec3 normal, vec3 tangent, vec3 bitangent)
{
    mat3 m = mat3(mView * mModel);

    vec3 n = normal;
    vec3 t = tangent;
    vec3 b = bitangent;

    return m * mat3(t, b, n);
}

void main()
{
    frag_pos = (mView * mModel * vec4(vert_pos, 1)).xyz;

    frag_uv  = vert_uv;

    frag_TBN = compute_TBN(vert_N, vert_T, vert_B);
    frag_light_pos = light.pos - frag_pos;

    gl_Position = mProjection * vec4(frag_pos, 1);
}
#endif

//*****************************************************************************
#ifdef FRAGMENT_SHADER
//*****************************************************************************

float Lambert_diffuse(vec3 n, vec3 v, vec3 l)
{
    return max(0.0, dot(n, l));
}

float Phong_specular(vec3 n, vec3 v, vec3 l)
{
    float shininess = 2;
    vec3  r = normalize(reflect(-l, n));
    return pow(max(0, dot(r, v)), 0.3*shininess);
}

void main(void)
{
    vec4 texel = texture2D(material.colormap, frag_uv);

    vec3 n = texture2D(material.normalmap, frag_uv).rgb*2.0 - 1.0;
    n = frag_TBN * n;   //n = normalize(frag_TBN * n);

    vec3 v = normalize(-frag_pos);
    vec3 l = normalize(frag_light_pos); 

    float lighting = 0.1 + Lambert_diffuse(n, v, l) + Phong_specular(n, v, l);
    
    texel.rgb = lighting * texel.rgb;

    gl_FragColor = texel;
    //gl_FragColor = vec4(n, 1);
    //gl_FragColor = vec4(1, 0, 0, 1);
}
#endif
