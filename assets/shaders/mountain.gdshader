shader_type spatial;

render_mode cull_back, diffuse_burley;

uniform float peak_height = 1.0;
uniform vec3 rock_color_a : source_color = vec3(0.45, 0.35, 0.25);
uniform vec3 rock_color_b : source_color = vec3(0.55, 0.45, 0.32);
uniform vec3 rock_color_dark : source_color = vec3(0.25, 0.18, 0.12);
uniform float rock_noise_scale = 8.0;
uniform float rock_detail_scale = 25.0;
// neighbors: x=right(+X), y=left(-X), z=down(+Z), w=up(-Z)
uniform vec4 neighbors = vec4(0.0);

varying float height_ratio;
varying vec3 world_pos_frag;

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
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// dx/dy: signed distance from center, -1 to 1
	float dx = (UV.x - 0.5) * 2.0;
	float dy = (UV.y - 0.5) * 2.0;

	// On neighbor sides, clamp so the shape doesn't fall off at the edge
	float sdx = dx;
	float sdy = dy;
	if (neighbors.x > 0.5 && dx > 0.0) sdx = min(dx, 0.35);
	if (neighbors.y > 0.5 && dx < 0.0) sdx = max(dx, -0.35);
	if (neighbors.z > 0.5 && dy > 0.0) sdy = min(dy, 0.35);
	if (neighbors.w > 0.5 && dy < 0.0) sdy = max(dy, -0.35);

	float dist = length(vec2(sdx, sdy));
	float pyramid = max(1.0 - dist, 0.0);
	pyramid = pyramid * pyramid * (3.0 - 2.0 * pyramid);

	// Jagged noise — uses world position so it tiles seamlessly
	float jag = noise(wp.xz * 5.0) * 0.3 + noise(wp.xz * 12.0) * 0.15 + noise(wp.xz * 24.0) * 0.06;
	float height = (pyramid + jag * pyramid) * peak_height;

	VERTEX.y += height;
	height_ratio = clamp(height / peak_height, 0.0, 1.0);
	world_pos_frag = wp;

	// Normals via finite differences
	float eps = 0.02;
	vec2 wp_r = wp.xz + vec2(eps, 0.0);
	vec2 wp_u = wp.xz + vec2(0.0, eps);
	float jR = noise(wp_r * 5.0) * 0.3 + noise(wp_r * 12.0) * 0.15;
	float jU = noise(wp_u * 5.0) * 0.3 + noise(wp_u * 12.0) * 0.15;
	float hR = (pyramid + jR * pyramid) * peak_height;
	float hU = (pyramid + jU * pyramid) * peak_height;
	vec3 tangent_x = vec3(eps, hR - height, 0.0);
	vec3 tangent_z = vec3(0.0, hU - height, eps);
	NORMAL = normalize(cross(tangent_z, tangent_x));
}

void fragment() {
	vec2 uv = world_pos_frag.xz;

	// Discard flat ground-level pixels — only keep raised mountain
	if (height_ratio < 0.01) discard;

	// Base color variation with FBM
	float n1 = fbm(uv * rock_noise_scale);
	vec3 base = mix(rock_color_a, rock_color_b, n1);

	// Fine detail — crack-like streaks
	float detail = noise(uv * rock_detail_scale + vec2(uv.y * 2.0, 0.0));
	base = mix(base, rock_color_dark, detail * 0.25);

	// Dark patches — subtle
	float patches = fbm(uv * rock_noise_scale * 0.5 + vec2(13.0, 7.0));
	base = mix(base, rock_color_dark, smoothstep(0.4, 0.7, patches) * 0.15);

	// Dark base, lighter peaks
	base = mix(rock_color_dark * 0.5, base * 1.3, height_ratio);

	ALBEDO = base;
	ROUGHNESS = 0.9;
}
