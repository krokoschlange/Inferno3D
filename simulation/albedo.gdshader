shader_type spatial;
render_mode cull_disabled;

uniform sampler3D density: repeat_disable;


uniform vec3 size;
uniform int samples;
uniform float step_size;
uniform sampler2D blue_noise: hint_roughness_gray;

uniform float scatter_factor;
uniform vec3 smoke_color: source_color;

uniform vec3 light_dir;
uniform vec3 light_color: source_color;
uniform vec3 ambient_light: source_color;
uniform int light_samples;
uniform float light_step_size;

uniform float frame_i;
const float phi = 1.61803398875;

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

	vec3 n_light_dir = normalize(light_dir);

	float transparency = 1.0;
	float diffuse = 0.0;
	for (int i = 0; i < samples; i++) {
		float dens = textureLod(density, pos_to_uvw(pos), 0).r;

		if (dens > 0.01) {
			float shadow_dens = 0.0;
			vec3 light_pos = pos + n_light_dir * light_step_size * noise_offset;
			for (int j = 0; j < light_samples; j++) {
				 light_pos += n_light_dir * light_step_size;
				if (!is_inside(light_pos)) {
					break;
				}
				shadow_dens += textureLod(density, pos_to_uvw(light_pos), 0).r;
			}
			float light = exp(-shadow_dens * light_step_size * scatter_factor);

			float ext = exp(-dens * scatter_factor * step_size);
			transparency *= ext;

			diffuse += light * transparency * scatter_factor * dens * step_size;
		}

		pos += pos_diff;
		if (!is_inside(pos)) {
			break;
		}
	}
	float alpha = 1.0 - transparency;
	ALBEDO = smoke_color * diffuse * light_color + ambient_light;
	ALPHA = alpha;
}

void light() {
	DIFFUSE_LIGHT = vec3(1.0);
	SPECULAR_LIGHT = vec3(0.0);
}