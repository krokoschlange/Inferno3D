shader_type spatial;
render_mode cull_disabled, unshaded;

uniform sampler3D density: repeat_disable;
uniform sampler3D fuel: repeat_disable;
uniform sampler3D temperature: repeat_disable;

uniform sampler2D blackbody_lut: source_color, repeat_disable;
uniform float emission_intensity;

uniform vec3 size;
uniform int samples;
uniform float step_size;
uniform sampler2D blue_noise: hint_roughness_gray;

uniform float scatter_factor;

uniform float frame_i;
const float phi = 1.61803398875;

vec3 blackbody(float temp) {
	return texture(blackbody_lut, vec2(clamp(temp / 10000.0, 0.0, 1.0)), 0.5).rgb * emission_intensity;
}

vec3 pos_to_uvw(vec3 pos) {
	return pos / size;
}

bool is_inside(vec3 pos) {
	return pos.x >= 0.0 && pos.x <= size.x && pos.y >= 0.0 && pos.y <= size.y && pos.z >= 0.0 && pos.z <= size.z;
}

void vertex() {
	VERTEX = (VERTEX.xyz + 0.5) * size;
}

void fragment() {
	vec3 pos;

	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, 1.0, 1);
	view_pos /= view_pos.w;
	if (FRONT_FACING) {
		pos = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(VERTEX, 1)).xyz;
	} else {

		vec3 cam_pos = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * view_pos).xyz;
		if (is_inside(cam_pos)) {
			pos = cam_pos;
		} else {
			discard;
		}
	}

	vec4 view_pos2 = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, 0.9, 1);
	view_pos2 /= view_pos2.w;

	vec3 view_dir = normalize(view_pos2.xyz - view_pos.xyz);
	if (dot(view_dir, VIEW) > 0.0)
	{
		view_dir *= -1.0;
	}
	vec3 pos_diff = mat3(INV_VIEW_MATRIX) * view_dir * step_size;

	ivec2 noise_coords = ivec2(FRAGCOORD.xy) % textureSize(blue_noise, 0);
	float noise_offset = fract(texelFetch(blue_noise, noise_coords, 0).r + frame_i * phi);
	pos += pos_diff * noise_offset;

	float transparency = 1.0;
	vec3 emit = vec3(0);
	for (int i = 0; i < samples; i++) {
		float dens = textureLod(density, pos_to_uvw(pos), 0).r;
		float temp = textureLod(temperature, pos_to_uvw(pos), 0).r;

		if (dens > 0.01) {
			float ext = exp(-dens * scatter_factor * step_size);
			transparency *= ext;

			emit += transparency * dens * blackbody(temp) * step_size;
		}
		float fuel_dens = textureLod(fuel, pos_to_uvw(pos), 0).r;
		if (fuel_dens > 0.01) {
			emit += transparency * fuel_dens * blackbody(temp);
		}

		pos += pos_diff;
		if (!is_inside(pos)) {
			break;
		}
	}
	ALBEDO = emit;
}
