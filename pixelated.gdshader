shader_type canvas_item;

// Basic configuration uniforms
uniform vec2 pixel_size = vec2(1.0, 1.0);
uniform float pixel_factor = 0.5;  // Controls the intensity of the effect
uniform bool enable_dithering = true;  // Toggle dithering pattern
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Dithering matrix
const mat4 dither_matrix = mat4(
    vec4(0.0, 8.0, 2.0, 10.0),
    vec4(12.0, 4.0, 14.0, 6.0),
    vec4(3.0, 11.0, 1.0, 9.0),
    vec4(15.0, 7.0, 13.0, 5.0)
) / 16.0;

vec2 get_pixel_coord(vec2 uv, vec2 size) {
    return floor(uv * size) / size;
}

float get_dither_value(vec2 screen_pos) {
    int x = int(mod(screen_pos.x, 4.0));
    int y = int(mod(screen_pos.y, 4.0));
    return dither_matrix[y][x];
}

void fragment() {
    // Calculate base pixelation
    vec2 norm_size = pixel_size * SCREEN_PIXEL_SIZE * pixel_factor;
    vec2 base_uv = get_pixel_coord(SCREEN_UV, 1.0 / norm_size);

    // Apply offset based on Y position for the stair-stepping effect
    float row_offset = floor(SCREEN_UV.y / norm_size.y);
    base_uv.x += mod(row_offset, 2.0) * norm_size.x * 0.5;

    // Get the pixel color
    vec4 color = textureLod(screen_texture, base_uv, 0.0);

    // Apply dithering if enabled
    if (enable_dithering) {
        float dither = get_dither_value(FRAGCOORD.xy);
        color.rgb += (dither - 0.5) * 0.1;
    }

    // Apply a slight edge enhancement
    vec2 pixel_offset = vec2(norm_size.x, 0.0);
    vec4 color_right = textureLod(screen_texture, base_uv + pixel_offset, 0.0);
    vec4 color_left = textureLod(screen_texture, base_uv - pixel_offset, 0.0);
    color = mix(color, (color_right + color_left) * 0.5, 0.1);

    COLOR = color;
}
