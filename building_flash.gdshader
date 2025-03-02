shader_type spatial;

uniform float flash_speed = 0.0;
uniform vec3 flash_color = vec3(0, 0, 0);
uniform vec3 red = vec3(1, 0, 0);
uniform vec3 green = vec3(0, 1, 0);
uniform vec3 blue = vec3(0, 0, 1);

void fragment() {
	vec3 flash;
	if (flash_color == red) {
		flash.r = sin((TIME * flash_speed) + 1.0) * 0.5;
		flash.g = 0.0;
		flash.b = 0.0;
	}
	else if (flash_color == green) {
		flash.r = 0.0;
		flash.g = sin((TIME * flash_speed) + 1.0) * 0.5;
		flash.b = 0.0;
	}
	else if (flash_color == blue) {
		flash.r = 0.0;
		flash.g = 0.0;
		flash.b = sin((TIME * flash_speed) + 1.0) * 0.5;
	}
	
	ALBEDO = flash;
}
