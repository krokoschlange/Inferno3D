#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(set = 0, binding = 0) uniform sampler3D velocity;
layout(set = 0, binding = 1) uniform sampler3D old_field;
layout(set = 0, binding = 2) uniform restrict writeonly image3D new_field;
layout(std140, set = 0, binding = 3) uniform restrict Params {
	float timestep;
	float rdx;
} params;

void main() {
	ivec3 coords = ivec3(gl_GlobalInvocationID);
	vec3 old_pos = (vec3(coords) + 0.5) - params.timestep * params.rdx * texelFetch(velocity, coords, 0).xyz;
	vec3 uvw = old_pos / vec3(textureSize(velocity, 0));
	vec4 new_val = textureLod(old_field, uvw, 0);
	imageStore(new_field, coords, new_val);
}
