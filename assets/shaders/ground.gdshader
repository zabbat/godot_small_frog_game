shader_type spatial;

uniform sampler2D tile_map : filter_linear;
uniform vec2 grid_size = vec2(10.0, 10.0);
uniform float ground_size_world = 20.0;

// Tile colors
uniform vec4 none_color : source_color = vec4(0.35, 0.25, 0.18, 1.0);
uniform vec4 grass_color_a : source_color = vec4(0.2, 0.45, 0.1, 1.0);
uniform vec4 grass_color_b : source_color = vec4(0.3, 0.6, 0.15, 1.0);
uniform vec4 grass_color_dark : source_color = vec4(0.1, 0.28, 0.05, 1.0);
uniform vec4 rock_color_a : source_color = vec4(0.4, 0.36, 0.3, 1.0);
uniform vec4 rock_color_b : source_color = vec4(0.5, 0.45, 0.38, 1.0);
uniform vec4 rock_color_dark : source_color = vec4(0.3, 0.25, 0.2, 1.0);

// Noise scale for grass variation
uniform float grass_noise_scale = 8.0;
uniform float grass_detail_scale = 25.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Simple hash-based noise (no texture needed)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep

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

vec3 grass_pattern(vec2 uv) {
	// Base color variation with noise
	float n1 = fbm(uv * grass_noise_scale);
	vec3 base = mix(grass_color_a.rgb, grass_color_b.rgb, n1);

	// Fine detail - blade-like streaks
	float detail = noise(uv * grass_detail_scale + vec2(0.0, uv.y * 3.0));
	base = mix(base, grass_color_dark.rgb, detail * 0.3);

	// Subtle dark patches
	float patches = fbm(uv * grass_noise_scale * 0.5 + vec2(42.0, 17.0));
	base = mix(base, grass_color_dark.rgb, smoothstep(0.4, 0.7, patches) * 0.25);

	return base;
}

vec3 rock_pattern(vec2 uv) {
	float n1 = fbm(uv * grass_noise_scale * 1.5);
	vec3 base = mix(rock_color_a.rgb, rock_color_b.rgb, n1);

	float cracks = noise(uv * grass_detail_scale * 1.2);
	base = mix(base, rock_color_dark.rgb, smoothstep(0.45, 0.55, cracks) * 0.5);

	float patches = fbm(uv * grass_noise_scale * 0.8 + vec2(13.0, 7.0));
	base = mix(base, rock_color_dark.rgb, smoothstep(0.5, 0.7, patches) * 0.3);

	return base;
}

void fragment() {
	// Map world position to tile UV (0..1 range over the ground)
	float half_size = ground_size_world / 2.0;
	vec2 tile_uv = (world_pos.xz + half_size) / ground_size_world;
	tile_uv = clamp(tile_uv, 0.0, 1.0);

	// Sample tile map — R = grass, G = rock
	// filter_linear on the sampler gives us smooth blending at borders
	vec2 tile_value = texture(tile_map, tile_uv).rg;
	float grass_val = tile_value.r;
	float rock_val = tile_value.g;

	// Generate patterns
	vec3 ground = none_color.rgb;
	vec3 grass = grass_pattern(world_pos.xz);
	vec3 rock = rock_pattern(world_pos.xz);

	// Layer blending: none -> rock -> grass (grass on top)
	vec3 result = mix(ground, rock, rock_val);
	result = mix(result, grass, grass_val);
	ALBEDO = result;
	ROUGHNESS = mix(0.9, 0.75, max(grass_val, rock_val));
}
