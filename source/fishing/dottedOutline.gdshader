shader_type canvas_item;

void fragment() {
	if ((int(FRAGCOORD.x) + int(FRAGCOORD.y)) % 4 < 2) {
		discard;
	}
}