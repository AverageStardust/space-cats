shader_type canvas_item;

uniform vec3 shadow_color: source_color;
uniform float shadow_mix;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = vec4(mix(shadow_color, COLOR.rgb, shadow_mix), tex.a);
}