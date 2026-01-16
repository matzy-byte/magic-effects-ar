shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D albedo_tex : source_color;
uniform float deform_amplitude = 0.08;
uniform float deform_speed = 1.5;
uniform float noise_scale = 2.0;

uniform vec3 rim_color = vec3(0.5, 0.8, 1.0);
uniform float rim_power = 2.5;
uniform float alpha = 0.85;

// Use vertex color as albedo
uniform bool use_vertex_color = true;

// Emission color
uniform vec3 emit_color = vec3(0.5, 0.8, 1.0);
uniform float emit_strength = 1.0; // multiplier for emission

/* -------- simple 3D value noise -------- */

float hash(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898,78.233,37.719))) * 43758.5453);
}

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

/* -------- vertex deformation -------- */

void vertex() {
    float t = TIME * deform_speed;
    float n = noise(VERTEX * noise_scale + vec3(t));
    VERTEX += NORMAL * (n - 0.5) * deform_amplitude;
}

/* -------- fragment shading -------- */

void fragment() {
    vec4 tex = texture(albedo_tex, UV);

    float rim = pow(1.0 - dot(NORMAL, VIEW), rim_power);

    vec3 color = tex.rgb + rim * rim_color;

    // Apply vertex color if enabled
    if (use_vertex_color) {
        color *= COLOR.rgb;
    }

    ALBEDO = color;
    ALPHA = tex.a * alpha * (use_vertex_color ? COLOR.a : 1.0);

    // Apply emission
    EMISSION = emit_color * emit_strength;
}
