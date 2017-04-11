//*****************************************************************************
//
// Simple GLSL shader
//
//*****************************************************************************

uniform mat4 mProjection;
uniform mat4 mView;
uniform mat4 mModel;

uniform float normal_length;

//-----------------------------------------------------------------------------

#ifdef VERTEX_SHADER
attribute vec3 vert_pos;
attribute vec3 vert_N;
#endif

//*****************************************************************************
//
#ifdef VERTEX_SHADER
//
//*****************************************************************************

out Geom
{
    vec3 normal;
} geom;

void main()
{
    gl_Position = vec4(vert_pos, 1);
    geom.normal = vert_N;    
}
#endif

//*****************************************************************************
//
#ifdef GEOMETRY_SHADER
//
//*****************************************************************************

layout(triangles) in;
layout(line_strip, max_vertices=6) out;

in Geom
{
    vec3 normal;
} geom[];

void main()
{
    mat4 MVP = mProjection * mView * mModel;
    int i;
    for(i = 0; i < gl_in.length(); i++)
    {
        vec3 P = gl_in[i].gl_Position.xyz;
        vec3 N = geom[i].normal.xyz;
    
        gl_Position = MVP * vec4(P, 1.0);
        EmitVertex();
    
        gl_Position = MVP * vec4(P + N * normal_length, 1.0);
        EmitVertex();
    
        EndPrimitive();
    }
}
#endif

//*****************************************************************************
//
#ifdef FRAGMENT_SHADER
//
//*****************************************************************************

void main(void)
{
    gl_FragColor = vec4(0, 1, 0, 1);
}
#endif
