shader_type spatial;
render_mode world_vertex_coords;

uniform sampler2D albedo : filter_linear_mipmap_anisotropic;
uniform sampler2D normal : filter_linear_mipmap_anisotropic;
uniform float roughness_scale = 0.5;
uniform sampler2D roughness : filter_linear_mipmap_anisotropic;

uniform vec2 offset = vec2(0.0,0.0);
uniform float scale = 1.0;
uniform float angle = 0.0;

void vertex() {
	float s = sin(angle);
	float c = cos(angle);
	mat2 rotationMatrix = mat2(vec2(c, -s), vec2(s, c));
	
	//VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	BINORMAL = vec3(0,1,0);
	TANGENT = cross(BINORMAL, NORMAL);
	
	// apply texture rotation to tangent/binormal
	BINORMAL = s*TANGENT + c*BINORMAL;
	TANGENT = c*TANGENT - s*BINORMAL;
	
	UV = vec2(dot(VERTEX, TANGENT), VERTEX.y) / max(scale, 0.01);
	
	
	UV = rotationMatrix * UV + offset;
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
	NORMAL_MAP = texture(normal, UV).rgb;
	ROUGHNESS = texture(roughness, UV).r * roughness_scale;
	SPECULAR = 0.5;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
