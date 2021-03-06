//-----------------------------------------------------------------------------

mat3 compute_TBN(vec4 normal, vec4 tangent)
{
    mat3 m = mat3(mView * mModel);
    //mat3 m = transpose(inverse(mat3(mModel)));

    vec3 n = m * normal.xyz;
    vec3 t = m * tangent.xyz;
    vec3 b = cross(n, t) * tangent.w;

    return mat3(t, b, n);
}

