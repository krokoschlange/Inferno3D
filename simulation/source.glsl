#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image3D density;
layout(r32f, set = 0, binding = 1) uniform restrict image3D fuel;
layout(rgba32f, set = 0, binding = 2) uniform restrict image3D velocity;
layout(std140, set = 0, binding = 3) uniform restrict Params {
	vec4 position;
	vec4 velocity;
	float radius;
	float density;
	float fuel_density;
	float explode;
	float rdx;
	float edge;
	float force_velocity;
} params;

const float e = 2.7182818284590452353602874713527;

void main() {
	ivec3 coords = ivec3(gl_GlobalInvocationID);
	vec3 coord_pos = vec3(coords) * params.rdx;
	vec3 source_pos = params.position.xyz;
	
	float dist = distance(coord_pos, source_pos);
	if (dist < params.radius) {
		float dens = imageLoad(density, coords).r;
		float rel_dist = dist / params.radius;
		float edge = 1 - (exp(pow(rel_dist, params.edge)) - 1) / (e - 1);
		float add_dens = params.density * edge;
		float new_dens = max(0, dens + add_dens);
		imageStore(density, coords, vec4(new_dens, 0, 0, 0));
		
		float fuel_dens = imageLoad(fuel, coords).r;
		float add_fuel = params.fuel_density * edge;
		float new_fuel = max(0, fuel_dens + add_fuel);
		imageStore(fuel, coords, vec4(new_fuel, 0, 0, 0));
		
		vec3 dir = coord_pos - source_pos;
		vec3 vel = params.velocity.xyz + dir * params.explode;
		vec3 old_vel = imageLoad(velocity, coords).xyz;
		float dens_vel_fac = new_dens < 0.01 ? 0.0 : clamp(params.density / new_dens, 0, 1);
		float fuel_vel_fac = new_fuel < 0.01 ? 0.0 : clamp(params.fuel_density / new_fuel, 0, 1);
		float vel_fac = max(dens_vel_fac, max(fuel_vel_fac, params.force_velocity));
		vec3 new_vel = mix(old_vel, vel, vel_fac);
		imageStore(velocity, coords, vec4(new_vel, 0));
	}
}
