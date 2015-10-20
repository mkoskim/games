//*****************************************************************************
//
// This is simple 'flat' shader. Combine with default input block.
//
//*****************************************************************************

//*****************************************************************************
//
#ifdef VERTEX_SHADER
//
//*****************************************************************************

void main()
{
    frag_uv = vert_uv;

    gl_Position = mProjection * mView * mModel * vec4(vert_pos, 1);
}
#endif

//*****************************************************************************
//
#ifdef FRAGMENT_SHADER
//
//*****************************************************************************

void main(void)
{
    vec4 texel = texture2D(material.colormap, frag_uv);

    // Discarding fully transparent fragments may or may not help at some cases,
    // at least when using depth buffer with transparency and without sorting
    // drawing order the result can be almost correct.

    if(texel.a < 1.0/255) discard;

    gl_FragColor = texel;
}
#endif

