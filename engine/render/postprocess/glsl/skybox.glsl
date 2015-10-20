//*****************************************************************************
//
// Skybox rendering
//
//*****************************************************************************

uniform mat4 projection;
uniform mat4 view;
uniform samplerCube skybox;

varying vec3 frag_uv;

//*****************************************************************************
//
#ifdef VERTEX_SHADER
//
//*****************************************************************************

attribute vec3 vert_pos;

void main()
{
    vec4 pos = projection * mat4(mat3(view)) * vec4(vert_pos, 1.0);
    gl_Position = pos.xyww;
    frag_uv = vert_pos;
}
#endif

//*****************************************************************************
//
#ifdef FRAGMENT_SHADER
//
//*****************************************************************************

void main(void)
{
    vec4 texel = textureCube(skybox, frag_uv);
    gl_FragColor = texel;
    //gl_FragColor = vec4(0.5, 0.5, 0.5, 1);
}
#endif

