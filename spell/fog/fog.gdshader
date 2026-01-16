shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D albedo_tex : source_color;

/* StandardMaterial-style Albedo Color */
uniform vec3 albedo_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float alpha = 0.85;

/* Saturation control */
uniform float saturation = 1.0; // 0 = gray, 1 = full color

/* Deformation */
uniform float deform_amplitude = 0.08;
uniform float deform_speed = 1.5;
uniform float noise_scale = 2.0;

/* Rim for water effect */
uniform vec3 rim_color = vec3(0.5, 0.8, 1.0);
uniform float rim_power = 2.5;

/* 3D value noise */
float hash(vec3 p){ return fract(sin(dot(p,vec3(12.9898,78.233,37.719)))*43758.5453); }
float noise(vec3 p){
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f*f*(3.0-2.0*f);
	float n = mix(
		mix(mix(hash(i+vec3(0,0,0)), hash(i+vec3(1,0,0)), f.x),
		    mix(hash(i+vec3(0,1,0)), hash(i+vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i+vec3(0,0,1)), hash(i+vec3(1,0,1)), f.x),
		    mix(hash(i+vec3(0,1,1)), hash(i+vec3(1,1,1)), f.x), f.y),
		f.z);
	return n;
}

/* Vertex deformation */
void vertex(){
	float t = TIME * deform_speed;
	float n = noise(VERTEX * noise_scale + vec3(t));
	VERTEX += NORMAL * (n - 0.5) * deform_amplitude;
}

/* Fragment shading */
void fragment(){
	vec4 tex = texture(albedo_tex, UV);

	// Mix with Albedo Color
	vec3 color = tex.rgb * albedo_color;

	// Apply saturation reduction
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(gray), color, saturation);

	// Add rim highlight
	float rim = pow(1.0 - dot(NORMAL, VIEW), rim_power);
	color += rim * rim_color;

	ALBEDO = color;
	ALPHA = tex.a * alpha;
}
