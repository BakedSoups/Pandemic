extends Camera2D

var scroll_speed : float = 500  
var zoom_factor : float = 1.5 

## Camera movement based on user input to allow users to explore wider ranges of data
func _process(delta):

	if Input.is_action_pressed("camera_move_right"):
		position.x += scroll_speed * delta
	if Input.is_action_pressed("camera_move_left"):
		position.x -= scroll_speed * delta
	if Input.is_action_pressed("camera_move_backward"):
		position.y += scroll_speed * delta
	if Input.is_action_pressed("camera_move_forward"):
		position.y -= scroll_speed * delta

	if Input.is_action_just_pressed("camera_zoom_in"):
		zoom *= zoom_factor 
	if Input.is_action_just_pressed("camera_zoom_out"):
		zoom *= 1 / zoom_factor 
