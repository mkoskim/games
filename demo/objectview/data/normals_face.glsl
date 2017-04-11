//*****************************************************************************
//
// Simple GLSL shader
//
//*****************************************************************************

uniform mat4 mProjection;
uniform mat4 mView;
uniform mat4 mModel;

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

void main()
{
    gl_Position = vec4(vert_pos, 1);
}
#endif

//*****************************************************************************
//
#ifdef GEOMETRY_SHADER
//
//*****************************************************************************

uniform float normal_length;

layout(triangles) in;
layout(line_strip, max_vertices=2) out;

void main()
{
    mat4 MVP = mProjection * mView * mModel;

    vec3 P0 = gl_in[0].gl_Position.xyz;
    vec3 P1 = gl_in[1].gl_Position.xyz;
    vec3 P2 = gl_in[2].gl_Position.xyz;
  
    vec3 V0 = P0 - P1;
    vec3 V1 = P2 - P1;
  
    vec3 N = cross(V1, V0);
    N = normalize(N);
  
    // Center of the triangle
    vec3 P = (P0+P1+P2) / 3.0;
  
    gl_Position = MVP * vec4(P, 1.0);
    EmitVertex();
  
    gl_Position = MVP * vec4(P + N * normal_length, 1.0);
    EmitVertex();
    
    EndPrimitive();
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
