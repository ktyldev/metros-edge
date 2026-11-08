shader_type spatial;
render_mode world_vertex_coords;

uniform vec3 tint : source_color = vec3(1,1,1);
uniform sampler2D albedo : filter_linear_mipmap_anisotropic;
uniform float normal_scale = 1.0;
uniform sampler2D normal : filter_linear_mipmap_anisotropic;
uniform float roughness_scale = 0.5;
uniform sampler2D roughness : filter_linear_mipmap_anisotropic;
uniform float specular = 0.5;

uniform vec2 offset = vec2(0.0,0.0);
uniform float scale = 1.0;
uniform float angle = 0.0;

void vertex() {
	float s = sin(angle);
	float c = cos(angle);
	mat2 rotationMatrix = mat2(vec2(c, -s), vec2(s, c));
	
	//VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	//BINORMAL = vec3(0,1,0);
	//TANGENT = cross(BINORMAL, NORMAL);
	
	// apply texture rotation to tangent/binormal
	//BINORMAL = s*TANGENT + c*BINORMAL;
	//TANGENT = c*TANGENT - s*BINORMAL;
	
	//UV = vec2(dot(VERTEX, TANGENT), VERTEX.y) / max(scale, 0.01);
	
	vec3 helper = (abs(NORMAL.y) < 0.99) ? vec3(0,1,0) : vec3(1,0,0);
	vec3 T = normalize(cross(helper, NORMAL));
	vec3 B = cross(NORMAL, T);
	
	UV = vec2(dot(VERTEX, T), dot(VERTEX, B)) / max(scale, 0.01);
	
	UV = rotationMatrix * UV + offset;
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb * tint;
	NORMAL_MAP = texture(normal, UV).rgb * normal_scale;
	ROUGHNESS = texture(roughness, UV).r * roughness_scale;
	SPECULAR = specular;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
