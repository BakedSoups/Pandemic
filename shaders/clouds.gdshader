shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_lambert;

uniform sampler2D noise_texture;
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float cloud_speed = 0.02;
uniform float cloud_density = 1.0;
uniform float cloud_coverage = 0.6;
uniform vec2 uv_scale = vec2(3.0, 1.5);

void fragment() {
    // Create UV coordinates for spherical mapping
    vec2 base_uv = UV * uv_scale;

    // Add time-based movement for swirling effect
    base_uv.x += TIME * cloud_speed;
    base_uv.y += TIME * cloud_speed * 0.7;

    // Sample noise texture for cloud pattern
    float noise1 = texture(noise_texture, base_uv).r;
    float noise2 = texture(noise_texture, base_uv * 2.0 + vec2(0.5, 0.3)).r;

    // Combine noise samples for more interesting pattern
    float cloud_pattern = (noise1 * 0.7 + noise2 * 0.3) * cloud_density;

    // Apply cloud coverage threshold
    float cloud_mask = smoothstep(1.0 - cloud_coverage, 1.0, cloud_pattern);

    // Set final color and transparency
    ALBEDO = cloud_color.rgb;
    ALPHA = cloud_color.a * cloud_mask;

    // Add some subtle depth to the clouds
    ROUGHNESS = 0.9;
    SPECULAR = 0.1;
}