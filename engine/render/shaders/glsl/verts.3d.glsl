//-----------------------------------------------------------------------------
// Basic vertex shader
//-----------------------------------------------------------------------------

void main()
{
	frag_uv  = vert_uv;
	frag_pos = (mModelView * vec4(vert_pos, 1)).xyz;

	frag_TBN = compute_TBN(vert_norm, vert_tangent);

	frag_light_pos      = light.pos - frag_pos;
	frag_light_strength = 1 - length(frag_light_pos)/light.radius;	
	
    gl_Position = mProjection * vec4(frag_pos, 1);
}

