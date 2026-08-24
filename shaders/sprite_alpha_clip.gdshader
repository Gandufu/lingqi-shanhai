shader_type canvas_item;

uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.12;
uniform float outline_width : hint_range(0.0, 8.0) = 4.0;
uniform vec4 outline_color : source_color = vec4(0.01, 0.035, 0.035, 0.82);
uniform float brightness : hint_range(0.5, 1.5) = 1.12;

void fragment() {
	vec4 tint = COLOR;
	vec4 sampled = texture(TEXTURE, UV);
	vec2 offset = TEXTURE_PIXEL_SIZE * outline_width;
	float neighbor_alpha = 0.0;
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(offset.x, 0.0)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(-offset.x, 0.0)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(0.0, offset.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(0.0, -offset.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + offset).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV - offset).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(offset.x, -offset.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(-offset.x, offset.y)).a);
	if (sampled.a < alpha_cutoff && neighbor_alpha >= alpha_cutoff) {
		COLOR = outline_color * tint;
	} else if (sampled.a < alpha_cutoff) {
		discard;
	} else {
		sampled.rgb *= brightness;
		sampled.a = smoothstep(alpha_cutoff, alpha_cutoff + 0.10, sampled.a);
		COLOR = sampled * tint;
	}
}
