#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(set = 0, binding = 0) uniform sampler3D field;
layout(set = 0, binding = 1) uniform restrict writeonly image3D curl;
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
	
	vec3 curl_val = vec3((wT.z - wB.z) - (wN.y - wF.y), (wN.x - wF.x, wR.z - wL.z), (wR.y - wL.y) - (wT.x - wB.x));
	imageStore(curl, coords, vec4(curl_val, 1));
}
