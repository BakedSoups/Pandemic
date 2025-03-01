extends Area3D

func _ready():
	# Connect the body_entered signal to our function
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	# Check if the body is a StaticBody3D that belongs to the camera
	if body is StaticBody3D and is_camera_related(body):
		print("Camera touched this hitbox!")

# Helper function to check if a node is related to the camera
func is_camera_related(node):
	var current = node
	while current:
		if current is Camera3D:
			return true
		current = current.get_parent()
	return false
