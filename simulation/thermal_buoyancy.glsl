#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict image3D velocity;
layout(set = 0, binding = 1) uniform sampler3D temperature;
layout(std140, set = 0, binding = 2) uniform restrict Params {
	vec4 up;
	float timestep;
	float buoyancy;
} params;

void main() {
	ivec3 coords = ivec3(gl_GlobalInvocationID);
	
	float temp = texelFetch(temperature, coords, 0).r;
	
	vec3 vel = imageLoad(velocity, coords).xyz;
	vel += params.up.xyz * (params.timestep * params.buoyancy * temp);
	
	imageStore(velocity, coords, vec4(vel, 0));
}
