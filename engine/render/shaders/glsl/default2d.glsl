//*****************************************************************************
//
// This is simple 'flat' shader for 2D graphics (supports alpha), also used
// lightless 3D shading.
//
//*****************************************************************************

//-----------------------------------------------------------------------------
// Uniforms
//-----------------------------------------------------------------------------

uniform mat4 mProjection;
uniform mat4 mModelView;

struct MATERIAL
{
    vec4 color;
    sampler2D colormap;
};

uniform MATERIAL material;

//-----------------------------------------------------------------------------
// VBO
//-----------------------------------------------------------------------------

#ifdef VERTEX_SHADER
attribute vec3 vert_pos;
attribute vec2 vert_uv;
#endif

//-----------------------------------------------------------------------------
// Vertex shader -> fragment shader
//-----------------------------------------------------------------------------

varying vec2 frag_uv;

//-----------------------------------------------------------------------------
#ifdef VERTEX_SHADER
//-----------------------------------------------------------------------------

void main()
{
    frag_uv = vert_uv;

    gl_Position = mProjection * mModelView * vec4(vert_pos, 1);
}
#endif

//-----------------------------------------------------------------------------
#ifdef FRAGMENT_SHADER
//-----------------------------------------------------------------------------

void main(void)
{
    vec4 texel = texture2D(material.colormap, frag_uv);

    // Discarding fully transparent fragments may or may not help at some cases,
    // at least when using depth buffer with transparency and without sorting
    // drawing order the result can be almost correct.

    if(texel.a < 1.0/255) discard;

    gl_FragColor = texel * material.color;
}
#endif

