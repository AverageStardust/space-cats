shader_type canvas_item;

uniform float wave_phase;

void vertex() {
	VERTEX.y += sin(VERTEX.x * TAU / 64.0 + wave_phase) * 4.0;
}