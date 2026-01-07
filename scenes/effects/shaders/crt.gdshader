shader_type canvas_item;

// CRT/Scanline shader for retro effect
uniform float intensity : hint_range(0.0, 1.0) = 0.3;
uniform float scanline_count : hint_range(100.0, 1000.0) = 300.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float noise_intensity : hint_range(0.0, 0.1) = 0.02;

// Simple pseudo-random function
float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Scanlines
	float scanline = sin(uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
	scanline = pow(scanline, 1.5) * scanline_intensity;
	
	// Subtle screen noise
	float noise = random(uv + TIME * 0.1) * noise_intensity;
	
	// Combine effects
	float effect = scanline + noise;
	
	// Apply as darkening overlay
	COLOR = vec4(0.0, 0.0, 0.0, effect * intensity);
}
