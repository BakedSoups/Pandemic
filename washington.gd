# NYC
# Washington
extends Node3D

@onready var building_mesh = $Area3D/MeshInstance3D
@onready var shader_material = building_mesh.get_surface_override_material(0)

@export_category("Infection Levels")
@onready var red = Vector3(Color.RED.r, Color.RED.g, Color.RED.b)
@onready var green = Vector3(Color.GREEN.r, Color.GREEN.g, Color.GREEN.b)
@onready var blue = Vector3(Color.BLUE.r, Color.BLUE.g, Color.BLUE.b)

@onready var flash_speed: float = 5.0;
@onready var flash_color: Vector3 = green;

func _ready():
	shader_material.set_shader_parameter("flash_speed", flash_speed)
	shader_material.set_shader_parameter("flash_color", flash_color)

func _process(delta):
	pass
