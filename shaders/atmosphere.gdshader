shader_type spatial;
render_mode blend_add, cull_back, unshaded, depth_draw_never;

uniform vec4 atmosphere_color : source_color = vec4(0.6, 0.8, 1.0, 0.1);
uniform float atmosphere_rim = 5.0;
uniform float atmosphere_intensity = 2.0;

void fragment() {
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), atmosphere_rim);
    ALBEDO = atmosphere_color.rgb;
    ALPHA = atmosphere_color.a * fresnel * atmosphere_intensity;
}