extends Node2D

var x_pos : float
var y_pos : float
var value : float
var radius : float = 4
var tooltip_label : Label
var is_hovered : bool = false

func _ready():
	tooltip_label = Label.new()
	tooltip_label.text = str(value) + " people"
	tooltip_label.visible = false 
	add_child(tooltip_label)

	set_process_input(true)

func is_mouse_over() -> bool:
	var mouse_pos = get_local_mouse_position()
	var distance = mouse_pos.distance_to(Vector2(x_pos, y_pos))
	return distance <= radius

func _input(event):
	if event is InputEventMouseMotion:
		if is_mouse_over():
			if !is_hovered:
				is_hovered = true
				tooltip_label.visible = true 
				tooltip_label.position = Vector2(x_pos + 15, y_pos - 15) 
		elif is_hovered:
			is_hovered = false
			tooltip_label.visible = false

func _draw():
	draw_circle(Vector2(x_pos, y_pos), radius, Color(0,0,0, 0.2))

	
func init(x : int, y : int, val : int):
	x_pos = x
	y_pos = y
	value = val
