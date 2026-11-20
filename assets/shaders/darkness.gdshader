shader_type canvas_item;
// Full-screen night overlay with a soft circle of lamp-light around the hero.

uniform vec2 rect_size = vec2(1080.0, 1920.0);
uniform vec2 light_pos = vec2(540.0, 960.0);
uniform float radius = 600.0;
uniform float softness = 400.0;
uniform float strength = 0.8;
uniform vec3 night_color : source_color = vec3(0.02, 0.03, 0.09);

void fragment() {
	float dist = distance(UV * rect_size, light_pos);
	float dark = smoothstep(radius - softness, radius, dist);
	COLOR = vec4(night_color, dark * strength);
}
