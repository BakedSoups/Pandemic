extends Node3D

var passenger_count = 0.0
var s_count = 0.0
var i_count = 0.0
var r_count = 0.0

var formatted_count = ""

@export_group("Flight Controls")
@export var auto_start_flight: bool = true  
@export var current_destination: String = ""     #current destination city code
@export var stop_at_ratio: float = 1.0 			 #stop at this ratio along the path (1.0 = complete journey)
@export var enable_flight_commands: bool = true  #enable flight direction commands

@export_group("Debug Options")
@export var debug_mode: bool = false 		    
@export var reset_plane_position: bool = false  

@export_node_path var node1_path: NodePath = "../SF"
@export_node_path var node2_path: NodePath = "../CHI"

@export var path_name: String = "GeneratedPath"
@export var create_on_ready: bool = true
@export var path_width: float = 2.0 
@export var path_material: Material
@export var path_color: Color = Color(1.0, 0.5, 0.0, 1.0)  #

@export_group("Curve Controls")
@export var curve_height_factor: float = 15.0  
@export var curve_origin_relative: bool = true  
@export var curve_origin_point: Vector3 = Vector3.ZERO 
@export var use_bezier_curve: bool = true

@export_group("Plane Settings")
@export var spawn_plane: bool = true
@export var plane_speed: float = 10.0 
@export_node_path("Node3D") var plane_model_path: NodePath = "Area3D/plane"
@export var plane_scale: Vector3 = Vector3(1, 1, 1)  
@export var custom_plane_rotation: Vector3 = Vector3(0, 0, 0) 

@export_group("Control Points")
@export var add_control_points: bool = true  
@export var control_point_count: int = 4 
@export var curve_tightness: float = 0.8 

var node1_instance: Node3D
var node2_instance: Node3D
var path_follow: PathFollow3D
var plane_model: Node3D
var path: Path3D
var is_flight_active: bool = true  
var target_progress_ratio: float = 1.0  
var flight_completed: bool = false 

static var path_cache := {}
static var city_node_cache := {}
static var plane_model_cache := {}
static var mesh_cache := {}
static var material_cache := {}

func _ready():
	if path_cache.size() == 0:
		call_deferred("preload_all_paths")

func create_path_between(start_pos: Vector3, end_pos: Vector3) -> Path3D:
	var cache_key = str(start_pos) + "_to_" + str(end_pos)
	
	if path_cache.has(cache_key):
		return path_cache[cache_key]
	
	var path := Path3D.new()
	path.name = "CachedPath_" + cache_key

	var curve := Curve3D.new()
	curve.add_point(start_pos)

	var direction = end_pos - start_pos
	var path_length = direction.length()
	var midpoint = (start_pos + end_pos) / 2.0
	var adaptive_height = curve_height_factor * clamp(path_length / 100.0, 0.5, 3.0)

	var outward_dir = ((start_pos - curve_origin_point).normalized() + (end_pos - curve_origin_point).normalized()).normalized()
	var curve_center = midpoint + outward_dir * adaptive_height

	for i in 2:  
		var t = float(i + 1) / 3.0
		var control1 = start_pos.lerp(curve_center, t)
		var control2 = curve_center.lerp(end_pos, t)
		var point = control1.lerp(control2, t)
		curve.add_point(point)

	curve.add_point(end_pos)
	path.curve = curve

	if debug_mode:
		print("Generated cached path between: ", start_pos, " and ", end_pos)
	
	path_cache[cache_key] = path
	
	return path

func preload_all_paths():
	var city_codes = ["SF", "CHI", "NYC", "LA", "MA", "WA", "LON", "PA"]
	
	for code in city_codes:
		if not city_node_cache.has(code):
			var city_node = find_city_by_code(code)
			if city_node:
				city_node_cache[code] = city_node
	
	for from_idx in range(city_codes.size()):
		for to_idx in range(city_codes.size()):
			if from_idx == to_idx:
				continue
				
			var from_code = city_codes[from_idx]
			var to_code = city_codes[to_idx]
			
			if not city_node_cache.has(from_code) or not city_node_cache.has(to_code):
				continue
				
			var from_node = city_node_cache[from_code]
			var to_node = city_node_cache[to_code]
			
			var key = from_code + "->" + to_code
			if not path_cache.has(key):
				var new_path = create_path_between(from_node.global_position, to_node.global_position)
				path_cache[key] = new_path
			
			if (from_idx * city_codes.size() + to_idx) % 4 == 0:
				await get_tree().process_frame

func _process(delta):
	if path_follow and spawn_plane:
		if reset_plane_position:
			path_follow.progress = 0.0
			reset_plane_position = false
			if debug_mode:
				print("Reset plane position to start of path")
		
		if is_flight_active and not flight_completed:
			path_follow.progress += plane_speed * delta
			
			if path_follow.progress_ratio >= target_progress_ratio:
				path_follow.progress_ratio = target_progress_ratio
				is_flight_active = false
				flight_completed = true
				
				if debug_mode:
					print("Flight completed - reached target ratio: ", target_progress_ratio)
					
				if target_progress_ratio < 1.0:
					if debug_mode:
						print("Stopped at waypoint")
				else:
					if debug_mode:
						print("Reached destination: ", current_destination, " - removing plane and path")
					
					await get_tree().create_timer(0.5).timeout
					
					if path:
						path.queue_free()
						path = null
						path_follow = null
						plane_model = null
		
		if path_follow:
			if path_follow.rotation_mode != PathFollow3D.ROTATION_ORIENTED:
				path_follow.rotation_mode = PathFollow3D.ROTATION_ORIENTED
				path_follow.use_model_front = true
				path_follow.loop = false
				path_follow.h_offset = 0
				path_follow.v_offset = 0

func find_city_by_code(city_code: String) -> Node3D:
	city_code = city_code.strip_edges().to_upper()
	if city_node_cache.has(city_code):
		return city_node_cache[city_code]
	
	var parent_node = get_parent()
	
	var direct_path = "../" + city_code
	if has_node(direct_path):
		var city_node = get_node(direct_path)
		city_node_cache[city_code] = city_node
		return city_node
	
	direct_path = "../" + city_code.capitalize()
	if has_node(direct_path):
		if debug_mode:
			print("Found city by capitalized path: " + direct_path)
		var city_node = get_node(direct_path)
		city_node_cache[city_code] = city_node
		return city_node
	
	var city_aliases = {
		"SF": "SF", "SFO": "SF", "SAN FRANCISCO": "SF",
		"CHI": "CHI", "CHICAGO": "CHI", "ORD": "CHI",
		"NYC": "NYC", "NEW YORK": "NYC", "JFK": "NYC",
		"LOS ANGELES": "LA", "LAX": "LA",
		"MIAMI": "MA",
		"WASHINGTON": "WA", "WASHINGTON DC": "WA", "DC": "WA",
		"LONDON": "LON", "LHR": "LON",
		"PARIS": "PA", "CDG": "PA"
	}
	
	if city_aliases.has(city_code):
		var node_name = city_aliases[city_code]
		var aliased_path = "../" + node_name
		if has_node(aliased_path):
			if debug_mode:
				print("Found city through alias: " + city_code + " -> " + node_name)
			var city_node = get_node(aliased_path)
			city_node_cache[city_code] = city_node
			return city_node
	
	if has_node("../SF"):
		var default_node = get_node("../SF")
		return default_node
	
	var city_names = ["SF", "CHI", "NYC", "LA", "MA", "WA", "LON", "PA"]
	for name in city_names:
		if has_node("../" + name):
			if debug_mode:
				print("WARNING: Using " + name + " as last resort fallback")
			var fallback_node = get_node("../" + name)
			return fallback_node
	
	if debug_mode:
		print("ERROR: Could not find ANY city nodes!")
	return null

func plane_directions(from_city: String, to_city: String, stop_ratio: float = 1.0) -> bool:
	return set_flight_directions(from_city, to_city, stop_ratio)

func set_flight_directions(from_city_code: String, to_city_code: String, stop_ratio: float = 1.0) -> bool:
	var route_key = from_city_code + "->" + to_city_code
	
	if not path_cache.has(route_key):
		var from_node = find_city_by_code(from_city_code)
		var to_node = find_city_by_code(to_city_code)
		
		if from_node and to_node:
			var new_path = create_path_between(from_node.global_position, to_node.global_position)
			path_cache[route_key] = new_path
		else:
			push_error("Cached path not found for: " + route_key)
			return false
	
	var cached_path = path_cache[route_key]
	path = cached_path.duplicate()
	add_child(path)

	path_follow = PathFollow3D.new()
	path_follow.name = "PlanePathFollow"
	path_follow.loop = false
	path_follow.use_model_front = true
	path_follow.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	path.add_child(path_follow)

	setup_plane()

	current_destination = to_city_code
	target_progress_ratio = clamp(stop_ratio, 0.0, 1.0)
	path_follow.progress_ratio = 0.0
	is_flight_active = true
	flight_completed = false

	return true
func setup_plane():
	if not path_follow:
		push_error("Path Creator: Cannot setup plane without a path")
		if debug_mode:
			print("ERROR: PathFollow3D node is null")
		return
	
	var optimized_plane = Node3D.new()
	optimized_plane.name = "OptimizedPlane_" + str(randi())
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "PlaneSphere"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.25
	sphere_mesh.height = 0.5
	mesh_instance.mesh = sphere_mesh
	
	var passenger_label = Label3D.new()
	passenger_label.name = "PassengerCount"
	passenger_label.position = Vector3(0, 0.8, 0)
	passenger_label.font_size = 16
	passenger_label.outline_size = 2
	passenger_label.billboard = true
	
	var debug_label = Label3D.new()
	debug_label.name = "DebugLabel"
	debug_label.position = Vector3(0, 1.2, 0)
	debug_label.font_size = 12
	debug_label.outline_size = 1
	debug_label.billboard = true
	var from_name = "unknown"
	if node1_instance:
		from_name = node1_instance.name
	debug_label.text = from_name + "->" + current_destination
	debug_label.modulate = Color(0, 1, 1, 1)
	
	optimized_plane.add_child(mesh_instance)
	optimized_plane.add_child(passenger_label)
	optimized_plane.add_child(debug_label)
	
	var s_value = s_count
	var i_value = i_count
	var r_value = r_count
	var total_passengers = s_value + i_value + r_value
	
	var display_text = ""
	if total_passengers >= 1000000:
		display_text = str(total_passengers / 1000000.0).pad_decimals(1) + "M"
	elif total_passengers >= 1000:
		display_text = str(total_passengers / 1000.0).pad_decimals(1) + "K"
	else:
		display_text = str(int(total_passengers))
	
	var total_active = max(1.0, total_passengers)
	var s_ratio = s_value / total_active
	var i_ratio = i_value / total_active
	var r_ratio = r_value / total_active
	
	passenger_label.text = display_text
	
	if i_value > 0 && i_ratio >= 0.1:  #if 10% or more infected, mark as infected
		passenger_label.text += " [I]"
		passenger_label.modulate = Color(1.0, 0.0, 0.0, 1.0)
	elif i_ratio >= s_ratio && i_ratio >= r_ratio && i_value > 0:
		passenger_label.text += " [I]"
		passenger_label.modulate = Color(1.0, 0.0, 0.0, 1.0)
	elif r_ratio >= s_ratio && r_ratio >= i_ratio && r_value > 0:
		passenger_label.text += " [R]"
		passenger_label.modulate = Color(0.0, 1.0, 0.0, 1.0)
	elif s_value > 0:
		passenger_label.text += " [S]"
		passenger_label.modulate = Color(0.0, 0.5, 1.0, 1.0)
	
	debug_label.text = from_name + "->" + current_destination + "\n" + "S:" + str(int(s_value)) + " I:" + str(int(i_value)) + " R:" + str(int(r_value))
	
	var sphere_color = Color(0, 0, 0, 1.0)
	
	if i_value > 0:
		if i_ratio >= 0.1:  
			sphere_color.r = 1.0
			sphere_color.g = 0.0
			sphere_color.b = max(0.0, 0.3 - i_ratio * 0.3)  
		else:
			sphere_color.r = min(1.0, i_ratio * 4.0)  # 4x multiplier for red (more aggressive)
			
			if s_value > 0:
				sphere_color.b = min(1.0, s_ratio * 1.5 * (1.0 - i_ratio * 2.0))
	else:
		if s_value > 0:
			sphere_color.b = min(1.0, s_ratio * 1.5)
			
		if r_value > 0:
			sphere_color.g = min(1.0, r_ratio * 1.5)
	
	var color_intensity = sphere_color.r + sphere_color.g + sphere_color.b
	if color_intensity < 0.5:
		if color_intensity > 0:
			var factor = 0.7 / color_intensity
			sphere_color.r *= factor
			sphere_color.g *= factor
			sphere_color.b *= factor
		else:
			sphere_color = Color(0.2, 0.2, 0.8, 1.0)
	
	var sphere_material = StandardMaterial3D.new()
	sphere_material.albedo_color = sphere_color
	sphere_material.emission_enabled = true
	sphere_material.emission = sphere_color
	sphere_material.emission_energy_multiplier = 1.5
	mesh_instance.material_override = sphere_material
	
	var size_factor = clamp(sqrt(total_passengers) / 100.0, 0.25, 1.0)
	mesh_instance.scale = Vector3(size_factor, size_factor, size_factor)
	
	plane_model = optimized_plane
	path_follow.add_child(plane_model)
	
	plane_model.position = Vector3.ZERO
	plane_model.scale = Vector3(1, 1, 1)
	plane_model.rotation = Vector3(0, PI, 0) + custom_plane_rotation
	
	path_follow.loop = false
	path_follow.use_model_front = true
	path_follow.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	path_follow.progress = 0.0


func plane_directions_str(command: String) -> bool:
	if not enable_flight_commands:
		return false
	
	var command_parts = command.strip_edges().split(" ")
	if command_parts.size() < 1:
		return false
	
	var route_part = command_parts[0]
	var route_cities = route_part.split("->")
	
	if route_cities.size() != 2:
		return false
	
	var from_city = route_cities[0].strip_edges().to_upper()
	var to_city = route_cities[1].strip_edges().to_upper()
	
	var stop_ratio = 1.0
	if command_parts.size() > 1:
		stop_ratio = float(command_parts[1])
	
	return set_flight_directions(from_city, to_city, stop_ratio)

func create_path_visualization():
	if not debug_mode:
		return
		
	var material_key = "path_viz_material"
	var path_viz_material
	
	if material_cache.has(material_key):
		path_viz_material = material_cache[material_key]
	else:
		path_viz_material = StandardMaterial3D.new()
		path_viz_material.albedo_color = path_color
		path_viz_material.emission_enabled = true
		path_viz_material.emission = path_color
		path_viz_material.emission_energy_multiplier = 2.0
		path_viz_material.flags_unshaded = true
		material_cache[material_key] = path_viz_material
	
	if path_material:
		path_viz_material = path_material
	
	var csg = CSGPolygon3D.new()
	csg.name = "PathVisualizerCSG"
	path.add_child(csg)
	
	csg.polygon = PackedVector2Array([
		Vector2(-path_width/2, 0),
		Vector2(path_width/2, 0),
		Vector2(path_width/2, path_width),
		Vector2(-path_width/2, path_width)
	])
	
	csg.mode = CSGPolygon3D.MODE_PATH
	csg.path_node = NodePath("..")
	csg.path_interval = 0.5
	csg.path_continuous_u = true
	csg.smooth_faces = true
	csg.material = path_viz_material

func bezier_quadratic(p0: Vector3, p1: Vector3, p2: Vector3, t: float) -> Vector3:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return q0.lerp(q1, t)

func parse_flight_command(command: String) -> bool:
	return plane_directions_str(command)

func print_node_tree(node: Node, indent: String = "  "):
	if not debug_mode:
		return
		
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_node_tree(child, indent + "  ")
		
func format_passenger_count():
	if passenger_count >= 1000000:
		formatted_count = str(passenger_count / 1000000.0).pad_decimals(1) + "M"
	elif passenger_count >= 1000:
		formatted_count = str(passenger_count / 1000.0).pad_decimals(1) + "K"
	else:
		formatted_count = str(int(passenger_count))

	return formatted_count
