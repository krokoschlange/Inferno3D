#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(set = 0, binding = 0) uniform sampler3D field;
layout(set = 0, binding = 1) uniform restrict writeonly image3D div;
layout(std140, set = 0, binding = 2) uniform restrict Params {
	float halfrdx;
} params;

void main() {
	ivec3 coords = ivec3(gl_GlobalInvocationID);
	vec4 wL = texelFetch(field, coords - ivec3(1, 0, 0), 0);
	vec4 wR = texelFetch(field, coords + ivec3(1, 0, 0), 0);
	vec4 wB = texelFetch(field, coords - ivec3(0, 1, 0), 0);
	vec4 wT = texelFetch(field, coords + ivec3(0, 1, 0), 0);
	vec4 wF = texelFetch(field, coords - ivec3(0, 0, 1), 0);
	vec4 wN = texelFetch(field, coords + ivec3(0, 0, 1), 0);
	float div_val = params.halfrdx * ((wR.x - wL.x) + (wT.y - wB.y) + (wN.z - wF.z));
	imageStore(div, coords, vec4(div_val));
}
