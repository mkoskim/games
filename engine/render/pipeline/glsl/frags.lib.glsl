//*****************************************************************************
//
// Lightning calculations:
//
//      n = surface normal
//      v = viewer direction
//      l = light direction
//
//*****************************************************************************

//-----------------------------------------------------------------------------
//
// About material roughness: it is intended that it is between 0 (smooth,
// very reflective, metallic, mirror-like) and 1 (light is scattered to
// all directions). This value need to be mapped to shading model in use.
//
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Lambert diffuse reflection
//-----------------------------------------------------------------------------

float Lambert_diffuse(vec3 n, vec3 v, vec3 l)
{
    return max(0, dot(n, l));
}

//-----------------------------------------------------------------------------
// Sort of Oren-Nayar shading, see: http://ruh.li/GraphicsOrenNayar.html
//-----------------------------------------------------------------------------

float OrenNayar_diffuse(vec3 n, vec3 v, vec3 l)
{
    float roughness = material.roughness;
    const float PI = 3.141592653589;

    float NdotL = dot(n, l);
    float NdotV = dot(n, v);

    float angleVN = acos(NdotV);
    float angleLN = acos(NdotL);
    
    float alpha = max(angleVN, angleLN);
    float beta = min(angleVN, angleLN);
    float gamma = dot(v - n * dot(v, n), l - n * dot(l, n));
    
    float roughness2 = roughness * roughness;

    // calculate A and B
    float A = 1.0 - 0.5 * (roughness2 / (roughness2 + 0.57));

    float B = 0.45 * (roughness2 / (roughness2 + 0.09));

    float C = sin(alpha) * tan(beta);

    // put it all together
    float L1 = max(0.0, NdotL) * (A + B * max(0.0, gamma) * C);
        
    return max(0, L1);
}

//-----------------------------------------------------------------------------
// Phong / Blinn-Phong specular reflection
//-----------------------------------------------------------------------------

float compute_Phong_f()
{
    float r = material.roughness;
    return 5 + (1 - sqrt(r)) * 25;
}

float Phong_specular(vec3 n, vec3 v, vec3 l)
{
    vec3  r = normalize(reflect(-l, n));
    float f = compute_Phong_f();
    return pow(max(0, dot(r, v)), f);
}

float BlinnPhong_specular(vec3 n, vec3 v, vec3 l)
{
    vec3  h = normalize(l + v);
    float f = compute_Phong_f();
    return pow(max(0, dot(n, h)), f);
}

//-----------------------------------------------------------------------------
// Cook-Torrance specular reflection, see: http://ruh.li/GraphicsCookTorrance.html
//-----------------------------------------------------------------------------

float CookTorrance_specular(vec3 n, vec3 v, vec3 l)
{
    // Material values
    float roughness = 0.2 + 0.4*material.roughness; // 0 : smooth, 1: rough
    float F0 = 0.4 + 0.6*(1 - material.roughness);
    //float F0 = 0.2 + material.extra;
    //float F0 = 1 - roughness; // fresnel reflectance at normal incidence
    
    // do the lighting calculation for each fragment.
    float NdotL = max(dot(n, l), 0.0);
    
    if(NdotL <= 0.0) return 0.0;

    // calculate intermediary values
    vec3  h = normalize(l + v);
    float NdotH = max(dot(n, h), 0.0); 
    float NdotV = max(dot(n, v), 0.0); // note: this could also be NdotL, which is the same value
    float VdotH = max(dot(v, h), 0.0);
    
    // geometric attenuation
    float NH2 = 2.0 * NdotH;
    float g1 = (NH2 * NdotV) / VdotH;
    float g2 = (NH2 * NdotL) / VdotH;
    float geoAtt = min(1.0, min(g1, g2));
 
    // roughness (or: microfacet distribution function)
    // beckmann distribution function
    float roughness2 = roughness * roughness;
    float r1 = 1.0 / ( 4.0 * roughness2 * pow(NdotH, 4.0));
    float r2 = (NdotH * NdotH - 1.0) / (roughness2 * NdotH * NdotH);
    float r = r1 * exp(r2);
    
    // fresnel, Schlick approximation
    float fresnel = F0 + (1 - F0) * pow(1.0 - VdotH, 5.0);
    //fresnel *= (1.0 - F0);
    //fresnel += F0;
    
    return clamp(NdotL * (fresnel * geoAtt * r) / (NdotV * NdotL * 3.14), 0, 1);
}

//-----------------------------------------------------------------------------
// Quantifying (for toon shader)
//-----------------------------------------------------------------------------

float quantify(float value, int quants)
{
    return float(int(value * quants)) / quants;
}

