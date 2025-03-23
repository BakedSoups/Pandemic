extends Node3D

@export_group("Flight Controls")
@export var auto_start_flight: bool = true  # Whether to start flight automatically
@export var current_destination: String = ""  # Current destination city code
@export var stop_at_ratio: float = 1.0  # Stop at this ratio along the path (1.0 = complete journey)
@export var enable_flight_commands: bool = true  # Enable flight direction commands

@export_group("Debug Options")
@export var debug_mode: bool = true
@export var reset_plane_position: bool = false  # Toggle this to reset the plane position

@export_node_path var node1_path: NodePath = "../SF"
@export_node_path var node2_path: NodePath = "../CHI"

@export var path_name: String = "GeneratedPath"
@export var create_on_ready: bool = true
@export var path_width: float = 2.0  # Increased width for better visibility
@export var path_material: Material
@export var path_color: Color = Color(1.0, 0.5, 0.0, 1.0)  # Bright orange for better visibility

@export_group("Curve Controls")
@export var curve_height_factor: float = 15.0  # Base height of the curve
@export var curve_origin_relative: bool = true  # Whether to curve relative to origin
@export var curve_origin_point: Vector3 = Vector3.ZERO  # Origin point for curving
@export var use_bezier_curve: bool = true  # Use smooth bezier curves

@export_group("Plane Settings")
@export var spawn_plane: bool = true
@export var plane_speed: float = 10.0  # Units per second
@export_node_path("Node3D") var plane_model_path: NodePath = "Area3D/plane"
@export var plane_scale: Vector3 = Vector3(1, 1, 1)  # Scale the plane model
@export var custom_plane_rotation: Vector3 = Vector3(0, 0, 0)  # Adjust plane rotation if needed

@export_group("Control Points")
@export var add_control_points: bool = true  # Enabled by default
@export var control_point_count: int = 4  # More control points for smoother curve
@export var curve_tightness: float = 0.8  # Higher value for less randomness

var node1_instance: Node3D
var node2_instance: Node3D
var path_follow: PathFollow3D
var plane_model: Node3D
var path: Path3D
var is_flight_active: bool = true  # Whether the plane is currently moving
var target_progress_ratio: float = 1.0  # Target position along the path (1.0 = end)
var flight_completed: bool = false  # Whether the flight has completed
var path_cache := {}
func _ready():
	preload_all_paths()

func create_path_between(start_pos: Vector3, end_pos: Vector3) -> Path3D:
	var path := Path3D.new()
	path.name = "CachedPath_" + str(start_pos) + "_to_" + str(end_pos)

	var curve := Curve3D.new()
	curve.add_point(start_pos)

	var direction = end_pos - start_pos
	var path_length = direction.length()
	var midpoint = (start_pos + end_pos) / 2.0
	var adaptive_height = curve_height_factor * clamp(path_length / 100.0, 0.5, 3.0)

	var outward_dir = ((start_pos - curve_origin_point).normalized() + (end_pos - curve_origin_point).normalized()).normalized()
	var curve_center = midpoint + outward_dir * adaptive_height

	for i in 2:  # Always 2 control points for this function
		var t = float(i + 1) / 3.0
		var control1 = start_pos.lerp(curve_center, t)
		var control2 = curve_center.lerp(end_pos, t)
		var point = control1.lerp(control2, t)
		curve.add_point(point)

	curve.add_point(end_pos)
	path.curve = curve

	if debug_mode:
		print("Generated cached path between: ", start_pos, " and ", end_pos)

	return path
func preload_all_paths():
	var city_codes = ["SF", "CHI", "NYC", "LA", "MA", "WA", "LON", "PA"]
	for from_code in city_codes:
		for to_code in city_codes:
			if from_code == to_code:
				continue

			var from_node = find_city_by_code(from_code)
			var to_node = find_city_by_code(to_code)

			if from_node and to_node:
				var key = from_code + "->" + to_code
				if not path_cache.has(key):
					var new_path = create_path_between(from_node.global_position, to_node.global_position)
					path_cache[key] = new_path

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
			path_follow.rotation_mode = PathFollow3D.ROTATION_ORIENTED
			path_follow.use_model_front = true
			path_follow.loop = false  # 
			
			path_follow.h_offset = 0
			path_follow.v_offset = 0
			

func print_node_tree(node: Node, indent: String = "  "):
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_node_tree(child, indent + "  ")

func create_path() -> Path3D:
	if not node1_path.is_empty():
		if debug_mode:
			print("Looking for node 1 at: ", node1_path)
		
		if has_node(node1_path):
			node1_instance = get_node(node1_path)
			if debug_mode:
				print("Found node 1: ", node1_instance.name)
		else:
			push_error("Path Creator: Node not found at path: " + str(node1_path))
			if debug_mode:
				print("Available nodes in scene:")
				print_node_tree(self)
	
	if not node2_path.is_empty():
		if debug_mode:
			print("Looking for node 2 at: ", node2_path)
		
		if has_node(node2_path):
			node2_instance = get_node(node2_path)
			if debug_mode:
				print("Found node 2: ", node2_instance.name)
		else:
			push_error("Path Creator: Node not found at path: " + str(node2_path))
			if debug_mode:
				print("Available nodes in scene:")
				print_node_tree(self)
	
	if not node1_instance or not node2_instance:
		push_error("Path Creator: Failed to find nodes")
		
		if debug_mode:
			print("Node1 path: ", node1_path)
			print("Node2 path: ", node2_path)
			print("Node1 instance exists: ", node1_instance != null)
			print("Node2 instance exists: ", node2_instance != null)
			
			node1_instance = Node3D.new()
			node1_instance.name = "DebugNode1"
			add_child(node1_instance)
			
			node2_instance = Node3D.new()
			node2_instance.name = "DebugNode2"
			node2_instance.position = Vector3(10, 0, 0)
			add_child(node2_instance)
			
			print("Created debug nodes as fallback")
		else:
			return null
	
	path = Path3D.new()
	path.name = path_name
	add_child(path)
	
	var curve = Curve3D.new()
	
	if debug_mode:
		print("Node 1 position: ", node1_instance.global_position)
		print("Node 2 position: ", node2_instance.global_position)
	
	var start_pos = node1_instance.global_position
	var end_pos = node2_instance.global_position
	
	curve.add_point(start_pos)
	
	if add_control_points and control_point_count > 0:
		var direction = end_pos - start_pos
		var path_length = direction.length()
		var midpoint = (start_pos + end_pos) / 2.0
		
		var adaptive_height = curve_height_factor * clamp(path_length / 100.0, 0.5, 3.0)
		
		var curve_center
		if curve_origin_relative:
			var origin_to_start = start_pos - curve_origin_point
			var origin_to_end = end_pos - curve_origin_point
			var origin_to_mid = midpoint - curve_origin_point
			
			var outward_dir = ((origin_to_start.normalized() + origin_to_end.normalized()) * 0.5).normalized()
			
			if debug_mode:
				print("Outward direction from origin: ", outward_dir)
			
			curve_center = midpoint + outward_dir * adaptive_height
		else:
			curve_center = midpoint + Vector3.UP * adaptive_height
		
		if debug_mode:
			print("Curve center: ", curve_center)
			print("Adaptive height: ", adaptive_height)
			
		if use_bezier_curve:
			for i in control_point_count:
				var t = float(i + 1) / (control_point_count + 1)
				var point
				
				if control_point_count == 1:
					point = bezier_quadratic(start_pos, curve_center, end_pos, t)
				else:
					var control1 = start_pos.lerp(curve_center, t)
					var control2 = curve_center.lerp(end_pos, t)
					point = control1.lerp(control2, t)
					
					if curve_tightness < 1.0:
						var random_offset = Vector3(
							randf_range(-1, 1), 
							randf_range(-1, 1),
							randf_range(-1, 1)
						) * (1.0 - curve_tightness) * path_length * 0.03
						
						point += random_offset
				
				curve.add_point(point)
				
				if debug_mode and i == 0:
					print("First control point: ", point)
		else:
			for i in control_point_count:
				var t = float(i + 1) / (control_point_count + 1)
				
				var horizontal_pos = start_pos.lerp(end_pos, t)
				
				var height_factor = 4.0 * t * (1.0 - t)  # Parabolic function with peak at t=0.5
				var vertical_offset = curve_center * height_factor
				
				var point = horizontal_pos.lerp(vertical_offset, height_factor)
				
				if curve_tightness < 1.0:
					var random_offset = Vector3(
						randf_range(-1, 1), 
						randf_range(-1, 1),
						randf_range(-1, 1)
					) * (1.0 - curve_tightness) * path_length * 0.03
					
					point += random_offset
				
				curve.add_point(point)
	
	curve.add_point(end_pos)
	
	path.curve = curve
	
	path_follow = PathFollow3D.new()
	path_follow.name = "PlanePathFollow"
	path_follow.loop = true
	path_follow.use_model_front = true  # Make the model face the direction of movement
	path_follow.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	path_follow.progress = 0  # Start at beginning of path
	path_follow.h_offset = 0  # No horizontal offset
	path_follow.v_offset = 0  # No vertical offset
	path.add_child(path_follow)
	
	create_path_visualization()
	
	return path

func bezier_quadratic(p0: Vector3, p1: Vector3, p2: Vector3, t: float) -> Vector3:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return q0.lerp(q1, t)

func create_path_visualization():
	var path_viz_material = StandardMaterial3D.new()
	path_viz_material.albedo_color = path_color
	path_viz_material.emission_enabled = true
	path_viz_material.emission = path_color
	path_viz_material.emission_energy_multiplier = 2.0  # Increased for better visibility
	path_viz_material.flags_unshaded = true  # Make it visible even in unlit areas
	
	if path_material:
		path_viz_material = path_material
	
	var tube = MeshInstance3D.new()
	tube.name = "PathVisualizer"
	path.add_child(tube)
	
	var tube_mesh = ImmediateMesh.new()
	tube.mesh = tube_mesh
	tube.material_override = path_viz_material
	
	draw_path_tube(tube_mesh, path.curve, path_width, path_viz_material)
	
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
		
	var curve = path.curve
	for i in range(curve.point_count):
		var sphere = MeshInstance3D.new()
		sphere.name = "PathPoint_" + str(i)
		path.add_child(sphere)
		
		var mesh = SphereMesh.new()
		mesh.radius = path_width * 1.5
		mesh.height = path_width * 3
		sphere.mesh = mesh
		
		sphere.position = curve.get_point_position(i)
		sphere.material_override = path_viz_material

# Helper function to draw a tube mesh along the path curve
func draw_path_tube(mesh: ImmediateMesh, curve: Curve3D, width: float, material: Material):
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	
	var steps = 100  # Resolution of the path
	var segments = 8  # Resolution of the tube cross-section
	
	for i in range(steps):
		var t1 = float(i) / steps
		var t2 = float(i+1) / steps
		
		if t2 > 1.0:
			t2 = 1.0
			
		var pos1 = curve.sample_baked(t1 * curve.get_baked_length())
		var pos2 = curve.sample_baked(t2 * curve.get_baked_length())
		
		if pos1.distance_to(pos2) < 0.01:
			continue
			
		var forward = (pos2 - pos1).normalized()
		var up = Vector3(0, 1, 0)
		
		if abs(forward.dot(up)) > 0.9:
			up = Vector3(1, 0, 0)
			
		var right = forward.cross(up).normalized()
		up = right.cross(forward).normalized()
		
		for s in range(segments):
			var angle1 = 2 * PI * s / segments
			var angle2 = 2 * PI * (s+1) / segments
			
			var v1 = pos1 + (right * cos(angle1) + up * sin(angle1)) * width
			var v2 = pos1 + (right * cos(angle2) + up * sin(angle2)) * width
			var v3 = pos2 + (right * cos(angle1) + up * sin(angle1)) * width
			var v4 = pos2 + (right * cos(angle2) + up * sin(angle2)) * width
			
			mesh.surface_add_vertex(v1)
			mesh.surface_add_vertex(v2)
			mesh.surface_add_vertex(v3)
			
			mesh.surface_add_vertex(v2)
			mesh.surface_add_vertex(v4)
			mesh.surface_add_vertex(v3)
			
	mesh.surface_end()

func setup_plane():
	if not path_follow:
		push_error("Path Creator: Cannot setup plane without a path")
		if debug_mode:
			print("ERROR: PathFollow3D node is null")
		return
	
	if debug_mode:
		print("Setting up plane, looking for model at: ", plane_model_path)
	
	var original_plane = null
	if not plane_model_path.is_empty():
		if has_node(plane_model_path):
			original_plane = get_node(plane_model_path)
			if debug_mode:
				print("Found original plane model: ", original_plane.name)
		else:
			if debug_mode:
				print("Plane model not found at path: ", plane_model_path)
				print("Available nodes in scene:")
				print_node_tree(self)
	
	if original_plane:
		plane_model = original_plane.duplicate()
		plane_model.name = "PlaneModel_" + str(randi())
		if debug_mode:
			print("Created duplicate of original plane")
	else:
		plane_model = MeshInstance3D.new()
		plane_model.name = "PlaneModel_Placeholder"
		
		var mesh = BoxMesh.new()
		mesh.size = Vector3(4, 1, 2)  # Bigger for better visibility
		plane_model.mesh = mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.1, 0.1)  # Bright red
		material.emission_enabled = true
		material.emission = Color(0.9, 0.1, 0.1)
		material.emission_energy_multiplier = 1.0
		plane_model.material_override = material
		
		if debug_mode:
			print("Created placeholder plane model")
	
	path_follow.add_child(plane_model)
	
	if debug_mode:
		print("Added plane to path_follow")
	
	plane_model.position = Vector3.ZERO
	
	path_follow.loop = false  # Changed to false to prevent looping
	path_follow.use_model_front = true
	path_follow.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	path_follow.progress = 0.0  # Start at the beginning of the path
	
	plane_model.scale = plane_scale
	
	plane_model.rotation = Vector3(0, PI, 0) + custom_plane_rotation # Base orientation + custom adjustments
	
	if debug_mode:
		print("Plane setup complete")
		print("Path position at 0: ", path.curve.get_point_position(0))
		print("Plane global position: ", plane_model.global_position)
		print("PathFollow position: ", path_follow.position)
func update_path():
	if path:
		path.queue_free()
	
	create_path()# Flight direction command handler
func set_flight_directions(from_city_code: String, to_city_code: String, stop_ratio: float = 1.0) -> bool:
	var route_key = from_city_code + "->" + to_city_code
	
	if not path_cache.has(route_key):
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

func parse_flight_command(command: String) -> bool:
	if not enable_flight_commands:
		return false
	
	var command_parts = command.strip_edges().split(" ")
	if command_parts.size() < 1:
		push_error("Invalid flight command format")
		return false
	
	var route_part = command_parts[0]
	var route_cities = route_part.split("->")
	
	if route_cities.size() != 2:
		push_error("Invalid route format. Should be 'CityA->CityB'")
		return false
	
	var from_city = route_cities[0].strip_edges().to_upper()
	var to_city = route_cities[1].strip_edges().to_upper()
	
	var stop_ratio = 1.0
	if command_parts.size() > 1:
		stop_ratio = float(command_parts[1])
	
	return set_flight_directions(from_city, to_city, stop_ratio)
func find_city_by_code(city_code: String) -> Node3D:
	city_code = city_code.strip_edges().to_upper()
	
	var parent_node = get_parent()
	
	var direct_path = "../" + city_code
	if has_node(direct_path):
		return get_node(direct_path)
	
	direct_path = "../" + city_code.capitalize()
	if has_node(direct_path):
		print("Found city by capitalized path: " + direct_path)
		return get_node(direct_path)
	
	var city_aliases = {
		"SF": "SF",
		"SFO": "SF",
		"SAN FRANCISCO": "SF",
		
		"CHI": "CHI",
		"CHICAGO": "CHI",
		"ORD": "CHI",
		
		"NYC": "NYC",
		"NEW YORK": "NYC",
		"JFK": "NYC",
		
		"LOS ANGELES": "LA",
		"LAX": "LA",
		
		"MIAMI": "MA",
		
		"WASHINGTON": "WA",
		"WASHINGTON DC": "WA",
		"DC": "WA",
		
		"LONDON": "LON",
		"LHR": "LON",
		
		"PARIS": "PA",
		"CDG": "PA"
	}
	
	if city_aliases.has(city_code):
		var node_name = city_aliases[city_code]
		var aliased_path = "../" + node_name
		if has_node(aliased_path):
			print("Found city through alias: " + city_code + " -> " + node_name)
			return get_node(aliased_path)
	
	if has_node("../SF"):
		return get_node("../SF")
	
	var city_names = ["SF", "CHI", "NYC", "LA", "MA", "WA", "LON", "PA"]
	for name in city_names:
		if has_node("../" + name):
			print("WARNING: Using " + name + " as last resort fallback")
			return get_node("../" + name)
	
	print("ERROR: Could not find ANY city nodes!")
	return null
func plane_directions(from_city: String, to_city: String, stop_ratio: float = 1.0) -> bool:
	return set_flight_directions(from_city, to_city, stop_ratio)

func plane_directions_str(command: String) -> bool:
	return parse_flight_command(command)
