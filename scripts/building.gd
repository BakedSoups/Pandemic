extends Node3D

@onready var building_materials = {
	"sf": $SF/Area3D/MeshInstance3D.get_surface_override_material(0),
	"chicago": $Chicago/Area3D/MeshInstance3D.get_surface_override_material(0),
	"london": $London/Area3D/MeshInstance3D.get_surface_override_material(0),
	"miami": $Miami/Area3D/MeshInstance3D.get_surface_override_material(0),
	"washington": $Washington/Area3D/MeshInstance3D.get_surface_override_material(0),
	"Paris": $Paris/Area3D/MeshInstance3D.get_surface_override_material(0),
	"nyc": $NYC/Area3D/MeshInstance3D.get_surface_override_material(0),
}

@export_category("SRI Color")
@onready var red = Vector3(Color.RED.r, Color.RED.g, Color.RED.b)
@onready var green = Vector3(Color.GREEN.r, Color.GREEN.g, Color.GREEN.b)
@onready var blue = Vector3(Color.BLUE.r, Color.BLUE.g, Color.BLUE.b)
# @onready var beige = Vector3(Color.BEIGE.r, Color.BEIGE.g, Color.BEIGE.b)

'''DEBUG
@onready var flash_speed: float = 10.0
@onready var flash_color: Vector3 = round(beige * pow(10.0, 2)) / pow(10.0, 2)
'''
'''TEMP
@onready var temp_colors = [red, green, blue] # DEBUG
@onready var temp_flash_speed: float = randf() + 2; # DEBUG
@onready var temp_flash_color: Vector3 = temp_colors[randi() % temp_colors.size()] # DEBUG
'''

func _ready():
	pass

func _process(delta):
	for building in building_materials:
		var material = building_materials[building]
		# > TEMP >
		
		if building == "sf":
			material.set_shader_parameter("factor", 5.0)
			material.set_shader_parameter("color", red)
		else:
			material.set_shader_parameter("factor", 0.0)
			material.set_shader_parameter("color", blue)
		# < TEMP <

''' TODO: 
	[*] Replace builing scripts with this builing script with single shader for all buildingings (building_flash.gdshader)
	[*] 1 script, 1 shader, 1 building scene, many scenes for each building
	[*] Separte logic for each building
	[ ] figure out python brain
	[] flash to the SRI
	[] ensure GPU and CPU work is ballanced
'''
