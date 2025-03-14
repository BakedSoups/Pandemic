shader_type spatial;

uniform vec3 color;
uniform float factor;

void fragment() {
	vec3 solid = step(vec3(1.0), color);
	vec3 flash = solid * sin(TIME * factor) * 0.5;
	ALBEDO = mix(solid, flash, min(solid, flash));
}

/* TODO:
[*] if else chain to step function
[*] independent flash
[ ] SRI dependent flash */