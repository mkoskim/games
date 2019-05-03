//*****************************************************************************
//
// Simple GLSL shader
//
//*****************************************************************************

//-----------------------------------------------------------------------------

struct VertInput
{
    vec3 pos;
    vec2 uv;
    vec3 T;
    vec3 B;
    vec3 N;
};

struct GeomInput
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
in  VertInput vert;
out GeomInput geom;

void main()
{
    gl_Position = vec4(vert.pos, 1);
    geom.normal = vert.N;
}
#endif

//*****************************************************************************
//
#ifdef GEOMETRY_SHADER
//
//*****************************************************************************

layout(triangles) in;
layout(line_strip, max_vertices=6) out;

in  GeomInput geom[];

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

out vec4 frag_color;

void main(void)
{
    frag_color = normal.color;
}
#endif
