#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image3D fuel;
layout(r32f, set = 0, binding = 1) uniform restrict image3D temperature;
layout(r32f, set = 0, binding = 2) uniform restrict image3D density;
layout(std140, set = 0, binding = 3) uniform restrict Params {
	float max_temp;
	float burn_temp;
	float cool_factor;
	float burn_factor;
	float smoke_factor;
} params;

void main() {
	ivec3 coords = ivec3(gl_GlobalInvocationID);
	
	float fuel_concentration = imageLoad(fuel, coords).r;
	
	float temp = imageLoad(temperature, coords).r;
	temp -= params.cool_factor * pow(temp / params.max_temp, 4);
	temp = max(0, temp);
	
	float max_temp = min(fuel_concentration * params.burn_temp, params.burn_temp);
	temp = max(temp, max_temp);
	
	imageStore(temperature, coords, vec4(temp, 0, 0, 0));
	
	float new_fuel_conc = fuel_concentration * params.burn_factor;
	
	float dens = imageLoad(density, coords).r;
	dens += (fuel_concentration - new_fuel_conc) * params.smoke_factor;
	imageStore(density, coords, vec4(dens, 0, 0, 0));
	
	imageStore(fuel, coords, vec4(new_fuel_conc, 0, 0, 0));
}
