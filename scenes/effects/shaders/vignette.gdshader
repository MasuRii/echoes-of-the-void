shader_type canvas_item;

// Vignette shader for subtle darkness at screen edges
uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float softness : hint_range(0.0, 1.0) = 0.5;
uniform float radius : hint_range(0.0, 2.0) = 0.8;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv * vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y));
	float vignette = smoothstep(radius, radius - softness, dist);
	float alpha = (1.0 - vignette) * intensity;
	COLOR = vec4(vignette_color.rgb, alpha);
}
