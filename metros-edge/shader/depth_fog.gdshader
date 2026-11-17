shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

uniform vec4 fog_color : source_color = vec4(1.0);
//uniform float amount = 1.0;
//uniform float fog_intensity = 1.0;

uniform float fog_start;
uniform float fog_end;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;
	//ALBEDO = vec3(1.0) - screen_color;

    // The depth can be read using this line. The values returned by it are between 0.0 - 1.0 and are non-linear.
	// If we plug this directly into the ALBEDO texture, you will notice that everything is white, unless we get very close to it.
	// In order to fix this, we need to linearize the value.
	float depth = texture(depth_texture, SCREEN_UV).r;
    //ALBEDO = vec3(depth);

	// Normalized Device Coordinates ('NDC' for short), are a way of representing point's position on the 2D screen, relative to the width and height of it.
	// It ranges from (-1, 1), where the bottom-left corner has a value of (-1, -1) and the top-right corner has a value of (1, 1) 
	vec3 ndc = vec3((SCREEN_UV * 2.0) - 1.0, depth * 2.0 - 1.0); 
    //ALBEDO = ndc;
	
	// To use the ndc, we need to convert it to the view (camera) space, we can do it by multiplying it by the inverse of the projection matrix.
	// Space view gives us values relative to the camera position, which means that the 'z' (forward/backward), will give us the distance
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	
	// view space -> world space
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	float height = world_pos.y;
	//ALBEDO = vec3(-height * 0.1, 0, 0);
	
//	// Using this depth, a simple depth fog shader can be written. We just need to mix the screen_color with the fog_color using the depth as a value to interpolate by 
	float fog_factor = clamp((height - fog_start) / (fog_end - fog_start), 0.0, 1.0);
	//float fog_factor = clamp(linear_depth * fog_intensity, 0.0, 1.0);
	vec4 fogged_color = mix(vec4(screen_color, 1.0), fog_color, fog_factor);
//
	ALBEDO = fogged_color.rgb; // we then apply the fog color and alpha to the albedo and alpha channels
	ALPHA = fogged_color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
