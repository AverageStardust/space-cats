shader_type canvas_item;

uniform float progress_pixel;
uniform vec4 progress_color: source_color;
varying vec2 position;

void vertex() {
	position = VERTEX;
}

void fragment() {
	if (position.x < progress_pixel) {
		COLOR *= progress_color;
	}
}