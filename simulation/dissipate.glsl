#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image3D field;

layout(std140, set = 0, binding = 1) uniform restrict Params {
	float factor;
} params;

void main() {
	ivec3 coords = ivec3(gl_GlobalInvocationID);
	vec4 old_val = imageLoad(field, coords);
	imageStore(field, coords, old_val * params.factor);
}
