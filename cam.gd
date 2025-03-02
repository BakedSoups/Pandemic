extends Camera2D

var scroll_speed : float = 500  
var zoom_factor : float = 1.5 

func _process(delta):

	if Input.is_action_pressed("ui_right"):
		position.x += scroll_speed * delta
	if Input.is_action_pressed("ui_left"):
		position.x -= scroll_speed * delta
	if Input.is_action_pressed("ui_down"):
		position.y += scroll_speed * delta
	if Input.is_action_pressed("ui_up"):
		position.y -= scroll_speed * delta

	if Input.is_action_pressed("ui_W"):
		position.y -= scroll_speed * delta  
	if Input.is_action_pressed("ui_A"):
		position.x -= scroll_speed * delta  
	if Input.is_action_pressed("ui_S"):
		position.y += scroll_speed * delta  
	if Input.is_action_pressed("ui_D"):
		position.x += scroll_speed * delta 

	if Input.is_action_just_pressed("ui_ScrollUp"):
		zoom *= zoom_factor 
	if Input.is_action_just_pressed("ui_ScrollDown"):
		zoom *= 1 / zoom_factor 
