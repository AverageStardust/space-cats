shader_type canvas_item;

uniform vec3 spear_color: source_color;

void fragment() {
	if (COLOR.a == 1.0 && COLOR.g == 0.0 && COLOR.r == COLOR.b) {
		COLOR.rgb = spear_color * COLOR.r;
	}
}