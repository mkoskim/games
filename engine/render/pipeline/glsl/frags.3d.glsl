//*****************************************************************************
//
// Default 3D fragment shader.
//
//*****************************************************************************

float Lighting(vec3 n, vec3 v, vec3 l)
{
    float spec = 1 - material.roughness;
    float diff = 1 - spec;

    return

        //Lambert_diffuse(n, v, l) +
        (0.75 + 0.25*diff) * Lambert_diffuse(n, v, l) +
        //(0.5 + 0.5*diff) * OrenNayar_diffuse(n, v, l) +

        //(0.5*spec + 0.5) * CookTorrance_specular(n, v, l) +
        clamp((3*spec + 0.2*diff) * BlinnPhong_specular(n, v, l), 0, 1) +

        0.0;
}

//-----------------------------------------------------------------------------

void main(void)
{
    //-------------------------------------------------------------------------
    // Material parameters
    //-------------------------------------------------------------------------

    vec4  texel = texture2D(material.colormap, frag_uv);
    float alpha = texel.a;

    //-------------------------------------------------------------------------
    // Discarding fully transparent pixels leaves depth value intact
    //-------------------------------------------------------------------------

    if(alpha < 1.0/255) discard;

    //-------------------------------------------------------------------------
    // Lightning
    //-------------------------------------------------------------------------

    vec3 n =
        (useNormalMapping)
        ? (texture2D(material.normalmap, frag_uv).rgb*2.0 - 1.0)
        : vec3(0, 0, 1);
    
    n = frag_TBN * n;   //n = normalize(frag_TBN * n);

    vec3 v = normalize(-frag_pos);
    vec3 l = normalize(frag_light_pos); 

    float lighting = clamp(frag_light_strength, 0, 1) * Lighting(n, v, l) + light.ambient;

    if(useQuants != 0) {
        lighting = quantify(lighting, useQuants);
    }

    //-------------------------------------------------------------------------
    // Fragment output
    //-------------------------------------------------------------------------

    gl_FragColor = vec4(lighting * texel.rgb * light.color, alpha);
    //gl_FragColor = vec4(lighting * light.color, alpha);
    //gl_FragColor = vec4((n + 1)/2, alpha);
    //gl_FragColor = vec4((frag_tangent.xyz + 1)/2, alpha);
    //gl_FragColor = vec4((s+1)/2, alpha);
}

