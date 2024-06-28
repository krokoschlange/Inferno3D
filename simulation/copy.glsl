#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(set = 0, binding = 0) uniform sampler3D source;
layout(set = 0, binding = 1) uniform restrict writeonly image3D target;

void main() {
	ivec3 coords = ivec3(gl_GlobalInvocationID);
	imageStore(target, coords, texelFetch(source, coords, 0));
}
