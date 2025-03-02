extends Node3D

@onready var spring_arm_3d: SpringArm3D = $cameraOrigin/SpringArm3D
@onready var pivot := $cameraOrigin
@export var sens := 15
@export var zoom := 0
@export var damping = 0.85 
@export var planet_view = true
@onready var mouse_delta = Vector2.ZERO
@onready var arm_length = spring_arm_3d.get_hit_length()
@onready var camera_rotating = false
@onready var planet_rotating = false
@export var transition_speed := 1.9
@onready var camera: Camera3D = $cameraOrigin/SpringArm3D/Camera3D
@onready var is_transitioning := false
@onready var previous_planet_view: bool = planet_view
@export var non_planet_tilt := 0.2
@export var inertia_factor := 0.92
@export var key_rotation_speed := -3
@export var key_rotation_sens := 6.5
@export var key_inertia := 0.9

var original_position: Vector3
var velocity := Vector3.ZERO
var camera_default_rotation: Vector3
var pivot_default_rotation: Vector3
var rotation_velocity := Vector2.ZERO
var last_mouse_position = Vector2.ZERO

@export var zoom_speed := 2
@export var near_planet_zoom_speed := 0.2
@export var zoom_transition_distance := 25.0
@export var zoom_min := 28
@export var zoom_max := 80
@export var zoom_smoothness := 0.05
@export var centering_speed := 2.5
@export var rotation_reset_speed := 2.0

var target_spring_length := 0.0
var zoom_velocity := 0.0
var centering_active := false
var rotation_reset_active := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	original_position = pivot.global_position
	camera_default_rotation = camera.rotation
	pivot_default_rotation = pivot.rotation
	target_spring_length = spring_arm_3d.spring_length

func _input(event): 
	if event is InputEventMouseMotion:
		mouse_delta = event.relative
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			camera_rotating = event.pressed
			if camera_rotating and !planet_view:
				# Store the mouse position when starting to rotate in non-planet mode
				last_mouse_position = event.position
				# Capture the mouse when rotation starts
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			elif !camera_rotating and !planet_view:
				# Release the mouse when rotation ends in non-planet mode
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				# Reset mouse to last known position
				get_viewport().warp_mouse(last_mouse_position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			planet_rotating = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_spring_length -= get_current_zoom_speed()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_spring_length += get_current_zoom_speed()
			
	if event.is_action_pressed("left_click"):
		planet_rotating = true
	if event.is_action_released("left_click"):
		planet_rotating = false

# Cubic easing out function for smoother transitions
func ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3)

# Smoothing function for rotation transitions
func smooth_approach(current: float, target: float, speed: float) -> float:
	var t = 1.0 - pow(0.01, speed)
	return lerp(current, target, t)

func get_current_zoom_speed() -> float:
	if !planet_view:
		return near_planet_zoom_speed
	
	var distance_to_transition: float = spring_arm_3d.spring_length - 20.0
	if distance_to_transition < zoom_transition_distance and distance_to_transition > 0:
		var t: float = distance_to_transition / zoom_transition_distance
		# Use a smoother curve for the transition
		t = ease_out_cubic(t)
		return lerp(near_planet_zoom_speed, float(zoom_speed), t)
	
	return zoom_speed
		
func _physics_process(delta: float) -> void:		
	if Input.is_action_just_pressed("quit"): 
		get_tree().quit() 
	
	var current_zoom_speed: float = get_current_zoom_speed()
		
	if Input.is_action_pressed("camera_zoom_in"):
		target_spring_length -= current_zoom_speed * delta
	if Input.is_action_pressed("camera_zoom_out"):
		target_spring_length += current_zoom_speed * delta
	
	if target_spring_length < zoom_min:
		target_spring_length = zoom_min
	if target_spring_length > zoom_max:
		target_spring_length = zoom_max
	
	spring_arm_3d.spring_length = lerp(spring_arm_3d.spring_length, target_spring_length, zoom_smoothness)
	
	var old_planet_view = planet_view
	if spring_arm_3d.get_hit_length() < 35:
		planet_view = false     
	else: 
		planet_view = true
	
	if old_planet_view != planet_view:
		previous_planet_view = old_planet_view
		is_transitioning = true
		
		if planet_view == true:
			velocity = Vector3.ZERO
			var reset_direction = original_position - pivot.global_position
			if reset_direction.length() > 0.5:
				centering_active = true
				velocity = reset_direction.normalized()
			rotation_reset_active = true
			rotation_velocity = Vector2.ZERO
			
			# If we're switching to planet view, ensure mouse is visible
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			# If camera was being rotated, stop rotation
			if camera_rotating:
				camera_rotating = false
	
	if planet_view:
		var direction = original_position - pivot.global_position
		var distance = direction.length()
		
		if distance > 0.01:
			var force_factor = 1.0
			if centering_active:
				force_factor = centering_speed
				
			direction = direction.normalized()
			velocity = velocity * inertia_factor + direction * delta * force_factor
			pivot.global_translate(velocity)
			
			if centering_active and distance < 0.5:
				centering_active = false
		
func _process(delta):
	if is_transitioning:
		if planet_view:
			camera.rotation.x = lerp(camera.rotation.x, camera_default_rotation.x, transition_speed * delta)
			if abs(camera.rotation.x - camera_default_rotation.x) < 0.005:
				camera.rotation.x = camera_default_rotation.x
				is_transitioning = false
		else:
			camera.rotation.x = lerp(camera.rotation.x, non_planet_tilt, transition_speed * delta)
			if abs(camera.rotation.x - non_planet_tilt) < 0.005:
				camera.rotation.x = non_planet_tilt
				is_transitioning = false
				
	if rotation_reset_active and planet_view:
		# resets the view 
		#pivot.rotation.x = smooth_approach(pivot.rotation.x, pivot_default_rotation.x, rotation_reset_speed * delta)
		#pivot.rotation.y = smooth_approach(pivot.rotation.y, pivot_default_rotation.y, rotation_reset_speed * delta)
		#pivot.rotation.z = smooth_approach(pivot.rotation.z, pivot_default_rotation.z, rotation_reset_speed * delta)
		
		# Reset camera rotation when pivoting back to center with easing
		camera.rotation.x = smooth_approach(camera.rotation.x, camera_default_rotation.x, rotation_reset_speed * delta)
		camera.rotation.y = smooth_approach(camera.rotation.y, camera_default_rotation.y, rotation_reset_speed * delta)
		camera.rotation.z = smooth_approach(camera.rotation.z, camera_default_rotation.z, rotation_reset_speed * delta)
		
		if abs(pivot.rotation.x - pivot_default_rotation.x) < 0.005 and \
		   abs(pivot.rotation.y - pivot_default_rotation.y) < 0.005 and \
		   abs(pivot.rotation.z - pivot_default_rotation.z) < 0.005 and \
		   abs(camera.rotation.x - camera_default_rotation.x) < 0.005 and \
		   abs(camera.rotation.y - camera_default_rotation.y) < 0.005 and \
		   abs(camera.rotation.z - camera_default_rotation.z) < 0.005:
			camera.rotation = camera_default_rotation
			rotation_reset_active = false
	
	if not is_transitioning:
		var key_input := Vector2.ZERO
		
		if Input.is_action_pressed("camera_move_right"):
			key_input.x -= 1.0
		if Input.is_action_pressed("camera_move_left"):
			key_input.x += 1.0
		if Input.is_action_pressed("camera_move_forward"):
			key_input.y += 1.0
		if Input.is_action_pressed("camera_move_backward"):
			key_input.y -= 1.0
			
		key_input *= key_rotation_speed * key_rotation_sens
		
		if key_input.length() > 0:
			rotation_velocity = rotation_velocity.lerp(key_input, 1.0 - key_inertia)
		else:
			rotation_velocity *= key_inertia
			
		pivot.rotate_y(deg_to_rad(rotation_velocity.x * delta))
		pivot.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(rotation_velocity.y * delta))
		
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(45))
		
		if planet_view:
			if planet_rotating:
				pivot.rotate_y(deg_to_rad(-mouse_delta.x * sens * delta))
				pivot.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(-mouse_delta.y * sens * delta))
		elif camera_rotating:
			camera.rotate_y(deg_to_rad(-mouse_delta.x * sens * delta))
			camera.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(-mouse_delta.y * sens * delta))
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(45))
	
	mouse_delta *= damping
