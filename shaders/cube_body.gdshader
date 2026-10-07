shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Shared by monster bodies and cube debris. Per-instance COLOR is the base tone.
// INSTANCE_CUSTOM: x = wound (0-1), y = glow (eyes), z = extra occlusion (0-1).
uniform float roughness_base : hint_range(0.0, 1.0) = 0.74;
uniform float ground_grime : hint_range(0.0, 1.0) = 0.42;
uniform float plane_contrast : hint_range(0.0, 0.5) = 0.16;
uniform float bevel_light : hint_range(0.0, 0.6) = 0.20;
uniform float bevel_round : hint_range(0.0, 1.5) = 0.85;
uniform vec3 rim_color : source_color = vec3(0.45, 0.62, 0.80);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.55;
uniform float glow_energy = 3.2;
uniform vec3 dust_color : source_color = vec3(0.30, 0.27, 0.24);
uniform float dust : hint_range(0.0, 1.0) = 0.0;

varying vec3 local_pos;
varying vec3 world_pos;
varying vec4 custom;

void vertex() {
	local_pos = VERTEX;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	custom = INSTANCE_CUSTOM;
}

void fragment() {
	vec3 a = abs(local_pos);
	vec3 s = sign(local_pos);
	// Dominant axis is the cube face; the two others drive the bevel edge response.
	vec3 face = vec3(0.0);
	float m = max(a.x, max(a.y, a.z));
	if (a.x >= m) face.x = s.x; else if (a.y >= m) face.y = s.y; else face.z = s.z;
	vec3 edge_vec = vec3(
		smoothstep(0.35, 0.47, a.x) * s.x,
		smoothstep(0.35, 0.47, a.y) * s.y,
		smoothstep(0.35, 0.47, a.z) * s.z);
	edge_vec -= face * dot(edge_vec, abs(face));
	float edge = clamp(length(edge_vec), 0.0, 1.0);
	vec3 n_local = normalize(face + edge_vec * bevel_round);
	NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(n_local, 0.0)).xyz);

	vec3 world_n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 albedo = COLOR.rgb;
	// Plane separation independent of the key light: sky-facing planes read lighter.
	albedo *= 1.0 + plane_contrast * world_n.y - plane_contrast * 0.55 * abs(world_n.x);
	albedo *= 1.0 + bevel_light * edge * (0.6 + 0.4 * world_n.y);
	albedo *= mix(1.0 - ground_grime, 1.0, smoothstep(0.0, 5.0, world_pos.y));
	albedo *= 1.0 - custom.z;
	albedo = mix(albedo, dust_color, dust);

	ALBEDO = albedo;
	ROUGHNESS = mix(roughness_base, 0.96, clamp(custom.x + dust, 0.0, 1.0));
	METALLIC = 0.04;
	SPECULAR = mix(0.38, 0.18, custom.x);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 glow = COLOR.rgb * custom.y * glow_energy;
	EMISSION = rim_color * fres * rim_strength * (0.55 + 0.45 * world_n.y) * (1.0 - custom.x * 0.7) + glow;
}
