shader_type canvas_item;

uniform float wave_phase;
uniform float wave_frequency;

void vertex() {
	float angle = atan(VERTEX.x, VERTEX.y);
	float wave = 0.0;
	wave += sin(angle * wave_frequency * 1.0 + wave_phase * -1.0 + 4.73) * 1.6;
	wave += sin(angle * wave_frequency * 2.0 + wave_phase * 2.0 + 2.07) * 0.8;
	wave += sin(angle * wave_frequency * 3.0 + wave_phase * -3.0 + 5.21) * 0.4;
	vec2 norm = normalize(VERTEX);
	VERTEX += norm * wave;
}