#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(set = 0, binding = 0) uniform sampler3D x;
layout(set = 0, binding = 1) uniform sampler3D b;
layout(set = 0, binding = 2) uniform restrict writeonly image3D f;
layout(std140, set = 0, binding = 3) uniform restrict Params {
	float alpha;
	float beta;
	float clear_x;
} params;

void main() {
	ivec3 coords = ivec3(gl_GlobalInvocationID);
	vec4 xL = texelFetch(x, coords - ivec3(1, 0, 0), 0);
	vec4 xR = texelFetch(x, coords + ivec3(1, 0, 0), 0);
	vec4 xB = texelFetch(x, coords - ivec3(0, 1, 0), 0);
	vec4 xT = texelFetch(x, coords + ivec3(0, 1, 0), 0);
	vec4 xF = texelFetch(x, coords - ivec3(0, 0, 1), 0);
	vec4 xN = texelFetch(x, coords + ivec3(0, 0, 1), 0);
	vec4 bC = texelFetch(b, coords, 0);
	vec4 new_val = vec4(0);
	if (params.clear_x > 0.5)
	{
		new_val = (params.alpha * bC) * params.beta;
	}
	else
	{
		new_val = (xL + xR + xT + xB + xN + xF + params.alpha * bC) * params.beta;
	}
	imageStore(f, coords, new_val);
}
