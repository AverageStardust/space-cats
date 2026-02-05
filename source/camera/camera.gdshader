shader_type canvas_item;

uniform sampler2D screenTexture: hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D lutTexture: repeat_disable, filter_nearest;
uniform float visibility;

const int lud_size = 64;
const float dither[16] = float[16](-0.4375,0.0625,-0.3125,0.1875,0.3125,-0.1875,0.4375,-0.0625,-0.25,0.25,-0.375,0.125,0.5,0.0,0.375,-0.125);
const float ditherWeight = 4.0 / float(lud_size);

vec3 filterCol(sampler2D lut, vec3 col, ivec2 position) {
	ivec2 worldPosition = position;
	float ditherOffset = dither[worldPosition.x % 4 + (worldPosition.y % 4) * 4];
	col += normalize(col) * ditherOffset * ditherWeight;
	ivec3 icol = ivec3(col * float(lud_size));
	icol = clamp(icol, 0, lud_size - 1);
	ivec2 uv = ivec2(icol.r + icol.b * lud_size, icol.g);
	return texelFetch(lut, uv, 0).rgb;
}

void fragment() {
	vec4 col = texture(screenTexture, SCREEN_UV);
	vec3 filteredCol = filterCol(lutTexture, col.rgb, ivec2(FRAGCOORD.xy));
	COLOR = vec4(filteredCol.rgb * visibility, col.a);
}