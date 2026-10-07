shader_type spatial;
render_mode cull_back, diffuse_burley;

// Miniature-set surface: world-space grime, ground-contact darkening and lit-window variation.
uniform vec3 base_color : source_color = vec3(0.5);
uniform float emissive = 0.0;
uniform float emission_energy = 1.8;

varying vec3 world_pos;
varying vec3 center_pos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	center_pos = MODEL_MATRIX[3].xyz;
}

void fragment() {
	vec3 world_n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 albedo = base_color;
	vec2 plane = abs(world_n.y) > 0.5 ? world_pos.xz : (abs(world_n.x) > 0.5 ? world_pos.zy : world_pos.xy);
	float grime = vnoise(plane * 0.55) * 0.6 + vnoise(plane * 2.3) * 0.4;
	albedo *= 0.84 + grime * 0.30;
	// Walls darken toward the street; roofs and tops keep their value.
	albedo *= mix(1.0, mix(0.62, 1.0, smoothstep(0.0, 3.5, world_pos.y)), 1.0 - abs(world_n.y));
	if (emissive > 0.5) {
		float lit = 0.55 + 0.9 * hash(center_pos.xy * 13.1 + center_pos.z);
		ALBEDO = albedo * 0.5;
		EMISSION = base_color * emission_energy * lit;
		ROUGHNESS = 0.4;
	} else {
		ALBEDO = albedo;
		ROUGHNESS = 0.88;
	}
	SPECULAR = 0.25;
}
