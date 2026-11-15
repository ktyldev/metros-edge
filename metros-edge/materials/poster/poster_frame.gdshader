shader_type spatial;

uniform sampler2D normal : filter_nearest;
uniform sampler2D albedo_array[6] : filter_nearest;
instance uniform int poster_index = 0;

void fragment() {
	// Called for every pixel the material is visible on.
	NORMAL_MAP = texture(normal, UV).rgb;
	vec4 color = texture(albedo_array[poster_index], UV);
	ALBEDO = color.rgb;
	ROUGHNESS = 0.4;
}
