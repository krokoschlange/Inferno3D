#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(set = 0, binding = 0) uniform sampler3D curl;
layout(rgba32f, set = 0, binding = 1) uniform restrict image3D velocity;
layout(std140, set = 0, binding = 2) uniform restrict Params {
	float halfrdx;
	float confinement;
} params;

void main() {
	ivec3 coords = ivec3(gl_GlobalInvocationID);
	float cL = length(texelFetch(curl, coords - ivec3(1, 0, 0), 0).xyz);
	float cR = length(texelFetch(curl, coords + ivec3(1, 0, 0), 0).xyz);
	float cB = length(texelFetch(curl, coords - ivec3(0, 1, 0), 0).xyz);
	float cT = length(texelFetch(curl, coords + ivec3(0, 1, 0), 0).xyz);
	float cF = length(texelFetch(curl, coords - ivec3(0, 0, 1), 0).xyz);
	float cN = length(texelFetch(curl, coords + ivec3(0, 0, 1), 0).xyz);
	vec3 cC = texelFetch(curl, coords, 0).xyz;
	
	vec3 N = vec3(cR - cL, cT - cB, cN - cF);
	vec3 conf = params.confinement * cross(normalize(N), cC);
	
	if (length(N) < 0.001)
	{
		conf = vec3(0);
	}
	vec3 new_vel = imageLoad(velocity, coords).xyz;
	new_vel += conf;
	imageStore(velocity, coords, vec4(new_vel, 0));
}
