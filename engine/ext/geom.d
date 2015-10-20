//*****************************************************************************
//
// Computer generated geometry
//
//*****************************************************************************

module engine.ext.geom;

//-----------------------------------------------------------------------------

import engine.render.util;
import engine.render.loader.mesh;

const vec2 center = vec2(0.5, 0.5);

//-----------------------------------------------------------------------------

Mesh rect(vec2 size, vec2 refp = vec2(0, 0))
{
    auto mesh = new Mesh(GL_TRIANGLES);

    vec2 r = vec2(size.x * refp.x, size.y * refp.y);
    vec2 a = vec2(0, 0) - r;
    vec2 b = size - r;

    mesh.addvertex(vec3(a.x, a.y, 0), vec2(0, 0), vec3(0, 0, 1));
    mesh.addvertex(vec3(b.x, a.y, 0), vec2(1, 0), vec3(0, 0, 1));
    mesh.addvertex(vec3(b.x, b.y, 0), vec2(1, 1), vec3(0, 0, 1));
    mesh.addvertex(vec3(a.x, b.y, 0), vec2(0, 1), vec3(0, 0, 1));

    mesh.addface(0, 1, 2);
    mesh.addface(0, 2, 3);

    return mesh;
}

auto rect(float width, float height, vec2 refp = vec2(0, 0))
{
    return rect(vec2(width, height), refp);
}

//-----------------------------------------------------------------------------

/*
Mesh plane(vec3 pos, vec3 x, vec3 y)
{
    auto mesh = new Mesh(GL_TRIANGLES);

    mesh.addvertex(pos, vec2(0, 0));
    mesh.addvertex(pos + x, vec2(1, 0));
    mesh.addvertex(pos + x + y, vec2(1, 1));
    mesh.addvertex(pos + y, vec2(0, 1));

    mesh.addface([0, 1, 2]);
    mesh.addface([0, 2, 3]);

    return mesh;
}
*/

//-----------------------------------------------------------------------------

Mesh circle(float radius, int steps)
{
    auto mesh = new Mesh(GL_TRIANGLE_FAN);

    mesh.addvertex(vec3(0, 0, 0), vec2(0.5, 0.5), vec3(0, 0, 1));
    mesh.addface(1);

    foreach(i; 0 .. steps + 1)
    {
        float a = 2*PI*i/steps;

        mesh.addvertex(
            vec3(cos(a)*radius, sin(a)*radius, 0),
            vec2(cos(a)+0.5, sin(a)+0.5),
            vec3(0, 0, 1)
        );
        mesh.addface(cast(ushort)(i+1));
    }

    return mesh;
}

/*
MeshPtr geom::circle(vec2 ref, float radius, int steps, vec4 incolor, vec4 outcolor)
{
    MeshPtr mesh(new Mesh(GL_TRIANGLE_FAN));

    mesh->add(vec2(0, 0), incolor);

    for(int i = 0; i < steps + 1; i++)
    {
        float a = 2*M_PI*i/steps;
        vec2 p = vec2(cos(a), sin(a)) * radius;

        mesh->add(p, outcolor);
    }

    return mesh;
}
*/

