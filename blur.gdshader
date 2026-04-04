shader_type canvas_item;

uniform float lod: hint_range(0.0, 10.0) = 2.0;
uniform sampler2D texture_to_apply : source_color, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment(){
	COLOR = texture(texture_to_apply, UV, lod);
	//COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, lod);
}