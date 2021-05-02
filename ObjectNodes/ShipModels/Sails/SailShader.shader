shader_type spatial;

render_mode cull_disabled;
uniform sampler2D texture_albedo : hint_albedo;
uniform vec4 albedo : hint_color;
uniform float wave_size = 1.0;
uniform float wave_speed = 1.0;
uniform float noise_strength = 5.0;
uniform float side_wind_strength = 0.2;
uniform float time_offset = 0.0;
uniform float sail_in = 1.0; // how far in the sail is, 0 means farest out, 1 means fully pulled in 


uniform sampler2D uv_offset_texture : hint_black;
uniform vec2 uv_offset_scale = vec2(-0.2,-0.1);
uniform vec2 time_scale = vec2(0.3, 0.0);
uniform float face_distortion = 0.5;

void vertex(){
	vec2 base_uv_offset = UV * uv_offset_scale;
	base_uv_offset += (time_offset+TIME) * time_scale;
	
	float noise = texture(uv_offset_texture,base_uv_offset).r;
	float texture_based_offset = UV.x *(noise-0.5)* noise_strength;
	texture_based_offset *= UV.x;
	
	VERTEX.y += texture_based_offset + UV.x * sin(UV.x * 2.0 * 3.14 - (time_offset+TIME) * wave_speed) * wave_size;
	
	VERTEX.z += texture_based_offset * face_distortion + UV.x * UV.x*side_wind_strength;
	VERTEX.x += texture_based_offset * -face_distortion*3.0*UV.x - sail_in*UV.x;
	
	
}


void fragment(){
	// Sample noise
	vec2 base_uv_offset = UV * uv_offset_scale;
	vec4 albedo_tex = texture(texture_albedo,UV);
	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a;
	base_uv_offset += TIME * time_scale;
	float noise = texture(uv_offset_texture, base_uv_offset).r;
	float color = noise*3.0;
	ALBEDO *= vec3(color*0.5,color*0.4,color*0.4); //Display noise. Blue for valleys, green for peaks
}
