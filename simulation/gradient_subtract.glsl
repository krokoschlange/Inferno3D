#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(set = 0, binding = 0) uniform sampler3D pressure;
layout(rgba32f, set = 0, binding = 1) uniform restrict image3D velocity;
layout(std140, set = 0, binding = 2) uniform restrict Params {
	float halfrdx;
} params;

void main() {
	ivec3 coords = ivec3(gl_GlobalInvocationID);
	float pL = texelFetch(pressure, coords - ivec3(1, 0, 0), 0).r;
	float pR = texelFetch(pressure, coords + ivec3(1, 0, 0), 0).r;
	float pB = texelFetch(pressure, coords - ivec3(0, 1, 0), 0).r;
	float pT = texelFetch(pressure, coords + ivec3(0, 1, 0), 0).r;
	float pF = texelFetch(pressure, coords - ivec3(0, 0, 1), 0).r;
	float pN = texelFetch(pressure, coords + ivec3(0, 0, 1), 0).r;
	vec3 new_vel = imageLoad(velocity, coords).xyz;
	new_vel -= params.halfrdx * vec3(pR - pL, pT - pB, pN - pF);
	imageStore(velocity, coords, vec4(new_vel, 0));
}
