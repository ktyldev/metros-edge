
shader_type spatial;

//uniform sampler2D normal : filter_nearest;
uniform sampler2D albedo_array[5] : filter_nearest;
instance uniform int storefront_index = 0;

void fragment() {
	// Called for every pixel the material is visible on.
	//NORMAL_MAP = texture(normal, UV).rgb;
	vec4 color;
	switch(storefront_index){
		case 0:
			color = texture(albedo_array[0], UV);
			break;
		case 1:
			color = texture(albedo_array[1], UV);
			break;
		case 2:
			color = texture(albedo_array[2], UV);
			break;
		case 3:
			color = texture(albedo_array[3], UV);
			break;
		case 4:
			color = texture(albedo_array[4], UV);
			break;
		//case 5:
		//	color = texture(albedo_array[5], UV);
		//	break;
	}
	
	ALBEDO = color.rgb;
	//ROUGHNESS = 0.4;
}
