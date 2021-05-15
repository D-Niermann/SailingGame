shader_type spatial;

render_mode cull_disabled, depth_draw_alpha_prepass;


uniform sampler2D texture_albedo : hint_albedo;
uniform float uv_offset_scale = 1.0;
uniform bool isBuilding = false;

void fragment(){
	vec2 base_uv_offset = UV * uv_offset_scale;
	vec4 albedo_tex = texture(texture_albedo,UV);
	if (isBuilding==true){
		albedo_tex.g = clamp(albedo_tex.g,0.03,1.0);
		albedo_tex.g *= 0.8;
		albedo_tex.r = albedo_tex.g;
		albedo_tex.b = albedo_tex.g;
	}
	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a;
}