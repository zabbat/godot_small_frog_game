shader_type spatial;

render_mode cull_back, diffuse_burley;

uniform float peak_height = 1.0;
uniform vec3 rock_color_a : source_color = vec3(0.45, 0.35, 0.25);
uniform vec3 rock_color_b : source_color = vec3(0.55, 0.45, 0.32);
uniform vec3 rock_color_dark : source_color = vec3(0.25, 0.18, 0.12);
uniform vec3 snow_color : source_color = vec3(0.95, 0.95, 0.97);
uniform float snow_line = 0.7;

varying float height_ratio;
varying vec3 world_pos;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void vertex() {
	height_ratio = clamp(VERTEX.y / max(peak_height, 0.01), 0.0, 1.0);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz;

	// Rock color with noise variation
	float n1 = fbm(uv * 8.0);
	vec3 base = mix(rock_color_a, rock_color_b, n1);

	// Fine detail streaks
	float detail = noise(uv * 25.0 + vec2(uv.y * 2.0, 0.0));
	base = mix(base, rock_color_dark, detail * 0.25);

	// Dark at base, lighter at peaks
	base = mix(rock_color_dark, base, 0.3 + height_ratio * 0.7);

	// Snow on peaks
	float snow_noise = fbm(uv * 16.0 + vec2(5.0, 3.0)) * 0.15;
	float snow_blend = smoothstep(snow_line - 0.05, snow_line + 0.1, height_ratio + snow_noise);
	base = mix(base, snow_color, snow_blend);

	ALBEDO = base;
	ROUGHNESS = mix(0.9, 0.7, snow_blend);
}
