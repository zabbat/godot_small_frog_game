shader_type spatial;

render_mode cull_back, blend_mix, diffuse_burley;

uniform vec3 ring_color : source_color = vec3(0.35, 0.25, 0.16);

void fragment() {
	// Circular fade: opaque at center, transparent at edges
	float dx = (UV.x - 0.5) * 2.0;
	float dy = (UV.y - 0.5) * 2.0;
	float dist = length(vec2(dx, dy));
	float fade = 1.0 - smoothstep(0.2, 0.9, dist);

	ALBEDO = ring_color;
	ALPHA = fade * 0.7;
}
