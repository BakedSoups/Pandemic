extends Node3D

@onready var building_materials = {
	"SF": $SF/Area3D/MeshInstance3D.get_surface_override_material(0),
	"CHI": $CHI/Area3D/MeshInstance3D.get_surface_override_material(0),
	"LON": $LON/Area3D/MeshInstance3D.get_surface_override_material(0),
	"MA": $MA/Area3D/MeshInstance3D.get_surface_override_material(0),
	"WA": $WA/Area3D/MeshInstance3D.get_surface_override_material(0),
	"PA": $PA/Area3D/MeshInstance3D.get_surface_override_material(0),
	"NYC": $NYC/Area3D/MeshInstance3D.get_surface_override_material(0),
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
	if Data.day_count == 0: 
		return -1
	for building in building_materials:
		var material = building_materials[building]
		# > TEMP >
		var current_day = "day_"+str(Data.day_count)
		var city_day = Data.dict_names[current_day]
		#
		var city_stats = city_day[building]["sir_history"]


		var current_stats = len(city_stats[0])-1 #they are all the same size this will get the last elelemtn of the list
		var S = city_stats[0][current_stats]
		var I = city_stats[1][current_stats]
		var R = city_stats[2][current_stats]
		var D = city_stats[3][current_stats]
		#if building == "CHI":
			#print(building,"stats:")
			#print("Current S: ",S )
			#print("Current I: ", I)
			#print("Current R: ", R)
			#print("Current R: ", D)
			
		if I > 20000:
			material.set_shader_parameter("factor", 5.0)
			material.set_shader_parameter("color", red)
		elif R > 20000:
			material.set_shader_parameter("factor", 0.0)
			material.set_shader_parameter("color", green)
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
