shader_type spatial;
render_mode cull_disabled, unshaded;

uniform sampler3D density: repeat_disable;

uniform float normal_smoothness = 1.0;
uniform float normal_strength = 1.0;

uniform vec3 size;
uniform int samples;
uniform float step_size;
uniform sampler2D blue_noise: hint_roughness_gray;

uniform float scatter_factor;

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

	float transparency = 1.0;
	vec3 emit = vec3(0);
	vec3 norm = vec3(0, 0, 1);
	
	vec3 diff_size = normal_smoothness / vec3(textureSize(density, 0));
	
	for (int i = 0; i < samples; i++) {
		float dens = textureLod(density, pos_to_uvw(pos), 0).r;

		if (dens > 0.01) {
			float ext = exp(-dens * scatter_factor * step_size);
			float diff = transparency;
			transparency *= ext;
			diff -= transparency;

			float dens_b = textureLod(density, pos_to_uvw(pos) + vec3(0, -1, 0) * diff_size.y, 0).r;
			float dens_t = textureLod(density, pos_to_uvw(pos) + vec3(0, 1, 0) * diff_size.y, 0).r;
			float dens_n = textureLod(density, pos_to_uvw(pos) + vec3(0, 0, 1) * diff_size.z, 0).r;
			float dens_f = textureLod(density, pos_to_uvw(pos) + vec3(0, 0, -1) * diff_size.z, 0).r;
			float dens_l = textureLod(density, pos_to_uvw(pos) + vec3(-1, 0, 0) * diff_size.x, 0).r;
			float dens_r = textureLod(density, pos_to_uvw(pos) + vec3(1, 0, 0) * diff_size.x, 0).r;

			vec3 local_norm = normalize(vec3(dens_l - dens_r, dens_b - dens_t, dens_f - dens_n));
			norm += local_norm * diff;
		}

		pos += pos_diff;
		if (!is_inside(pos)) {
			break;
		}
	}
	if (transparency < 1.0) {
		norm.xy /= 1.0 - transparency;
	}
	norm.xy *= normal_strength;
	norm = normalize(norm);
	ALBEDO = vec3(norm * 0.5 + 0.5);
}