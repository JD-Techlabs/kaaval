shader_type canvas_item;
// Solid white silhouette for the 0.08 s hit flash.

void fragment() {
	COLOR = vec4(1.0, 1.0, 1.0, texture(TEXTURE, UV).a);
}
