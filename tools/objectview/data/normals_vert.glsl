//*****************************************************************************
//
// Simple GLSL shader
//
//*****************************************************************************

//-----------------------------------------------------------------------------

#ifdef VERTEX_SHADER
attribute vec3 vert_pos;
attribute vec3 vert_N;
#endif

struct Vertex2Geom
{
    vec3 normal;
};

//-----------------------------------------------------------------------------
// Options
//-----------------------------------------------------------------------------

uniform struct {
    float length;
    vec4  color;
} normal;

//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Frame wide settings
//-----------------------------------------------------------------------------

uniform mat4 mProjection;
uniform mat4 mView;

//-----------------------------------------------------------------------------

uniform mat4 mModel;

//*****************************************************************************
//
#ifdef VERTEX_SHADER
//
//*****************************************************************************

out Vertex2Geom geom;

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

in  Vertex2Geom geom[];

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
    
        gl_Position = MVP * vec4(P + N * normal.length, 1.0);
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
    gl_FragColor = normal.color;
}
#endif
