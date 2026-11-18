// shader based on: https://godotshaders.com/shader/linear-depth-depth-fog/

shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

instance uniform vec4 fog_color : source_color = vec4(1.0);
instance uniform float fog_end = 20.0;

varying vec3 world_pos_v;
varying vec3 world_normal_v;

void vertex() {
	world_pos_v = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal_v = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;

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
	
	// world pos of the scene point behind the fragment
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	
	float dist = dot(world_pos - world_pos_v, world_normal_v);
	float fog_factor = clamp(dist / -abs(fog_end), 0.0, 1.0);
	fog_factor = smoothstep(0, 1, fog_factor);
	
	vec4 fogged_color = mix(vec4(screen_color, 1.0), fog_color, fog_factor);
//
	ALBEDO = fogged_color.rgb; // we then apply the fog color and alpha to the albedo and alpha channels
	ALPHA = fog_factor;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
