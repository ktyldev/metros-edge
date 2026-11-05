shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

vec3 linear_to_srgb(vec3 linear_color) {
    const vec3 a = vec3(0.055);
    return mix(
        (vec3(1.0) + a) * pow(linear_color, vec3(1.0 / 2.4)) - a,
        12.92 * linear_color,
        lessThan(linear_color, vec3(0.0031308))
    );
}

void fragment() {
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 color = vec4(linear_to_srgb(vec3(0.0,0.491,0.922)),1.0);
	if (color.r < 0.5) {
		COLOR.r = 2.0 * screen.r * color.r;
	} else {
		COLOR.r = 1.0-2.0*(1.0-screen.r)*(1.0-color.r);
	}
	if (color.g < 0.5) {
		COLOR.g = 2.0 * screen.g * color.g;
	} else {
		COLOR.g = 1.0-2.0*(1.0-screen.g)*(1.0-color.g);
	}
	if (color.b < 0.5) {
		COLOR.b = 2.0 * screen.b * color.b;
	} else {
		COLOR.b = 1.0-2.0*(1.0-screen.b)*(1.0-color.b);
	}
	//COLOR.g = 1.0-2.0*(1.0-screen.g)*(1.0-color.g);
	//COLOR.b = 1.0-2.0*(1.0-screen.b)*(1.0-color.b);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
