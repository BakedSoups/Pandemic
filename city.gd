extends Area3D

func _ready():
	# Connect both enter and exit signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_body_entered(body):
	if is_camera_related(body):
		print("entering ", name)
	
func _on_body_exited(body):
	if is_camera_related(body):
		print("leaving ", name)
		
func _on_area_entered(area):
	if is_camera_related(area):
		print("entering ", name)
		
func _on_area_exited(area):
	if is_camera_related(area):
		print("leaving ", name)
		
func is_camera_related(node):
	var current = node
	while current:
		if current.name == "Camera3D":
			return true
		current = current.get_parent()
	return false
