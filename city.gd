extends Area3D

<<<<<<< HEAD
func _ready():
	# Connect both enter and exit signals
=======
var rich_text_label = null

func _ready():
	# Connect signals
>>>>>>> city
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
<<<<<<< HEAD

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
=======
	
	# Debug: Print this node's path from root
	var path_from_root = get_path_to(get_tree().root)
	print("This node's path from root: ", path_from_root)
	
	# Try to find the RichTextLabel
	var canvas_layer = get_tree().root.find_child("CanvasLayer", true, false)
	if canvas_layer:
		print("Found CanvasLayer at: ", canvas_layer.get_path())
		rich_text_label = canvas_layer.find_child("RichTextLabel", true, false)
		if rich_text_label:
			print("Found RichTextLabel at: ", rich_text_label.get_path())
		else:
			print("Could not find RichTextLabel under CanvasLayer")
	else:
		print("Could not find CanvasLayer in the scene")

func _on_body_entered(body):
	if is_camera_related(body):
		update_text(name)
	
func _on_body_exited(body):
	if is_camera_related(body):
		update_text(name)
		
func _on_area_entered(area):
	if is_camera_related(area):
		update_text(name)
		
func _on_area_exited(area):
	if is_camera_related(area):
		update_text(name)
		
func is_camera_related(node):
	var current = node

>>>>>>> city
	while current:
		if current.name == "Camera3D":
			return true
		current = current.get_parent()
	return false
<<<<<<< HEAD
=======

func update_text(message):
	if rich_text_label:
		rich_text_label.text = message 
		Data.Current_City = message.to_upper()
		rich_text_label.scroll_to_line(rich_text_label.get_line_count() - 1)
	else:
		print("RichTextLabel not found, message: ", message)
>>>>>>> city
