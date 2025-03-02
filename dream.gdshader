shader_type canvas_item;

uniform vec2 scale = vec2(1.0);
uniform float speed : hint_range(0.1, 2.0) = 0.5;
uniform vec4 pink : source_color = vec4(1.0, 0.4, 0.7, 0.2);
uniform vec4 blue : source_color = vec4(0.4, 0.6, 1.0, 0.2);

// Function to create smooth noise
vec2 random(vec2 uv) {
    uv = vec2(dot(uv, vec2(127.1,311.7)),
              dot(uv, vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);

    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix( mix( dot( random(uv_index + vec2(0.0,0.0) ), uv_fract - vec2(0.0,0.0) ),
                     dot( random(uv_index + vec2(1.0,0.0) ), uv_fract - vec2(1.0,0.0) ), blur.x),
                mix( dot( random(uv_index + vec2(0.0,1.0) ), uv_fract - vec2(0.0,1.0) ),
                     dot( random(uv_index + vec2(1.0,1.0) ), uv_fract - vec2(1.0,1.0) ), blur.x), blur.y);
}

void fragment() {
    // Create flowing movement
    vec2 motion = vec2(TIME * speed, TIME * speed * 0.5);
    vec2 scaled_uv = UV * scale + motion;

    // Generate multiple layers of noise for a dreamy effect
    float n = noise(scaled_uv);
    n += noise(scaled_uv * 2.0) * 0.5;
    n += noise(scaled_uv * 4.0) * 0.25;
    n = n / (1.0 + 0.5 + 0.25);

    // Normalize the noise
    n = n * 0.5 + 0.5;

    // Mix colors based on noise
    COLOR = mix(pink, blue, n);
}