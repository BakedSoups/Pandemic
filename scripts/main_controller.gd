extends Node2D
var DIR = OS.get_executable_path().get_base_dir()
var interpreter_path = "res://Python_Brain/venv/Scripts/python"
var script_path = "res://Python_Brain/preload.py"
# Called when the node enters the scene tree for the first time.
func _ready():
	if !OS.has_feature("standalone"): # if NOT exported version
		interpreter_path = ProjectSettings.globalize_path("res://Python_Brain/venv/Scripts/python")
		script_path = ProjectSettings.globalize_path("res://Python_Brain/preload.py")
		
func notify(title="", subtitle="", body=""):
	var output = []
	var exit_code = OS.execute(interpreter_path, [script_path, title, subtitle, body], output, true)
	var names = FileAccess.get_file_as_string("res://Python_Brain/pandemic_simulation.json")
	var dict_names = JSON.parse_string(names)
	print("Exit code: ", exit_code)
	print("Output: ", output)
	
	Data.dict_names = dict_names
#save into a global dictionary

func _on_start_simulation_button_down() -> void:
	print("Starting simulation...")
	notify("Simulation", "Started", "The simulation has begun!")

func _on_day_add_button_down() -> void:
	Data.day_count += 1
	var rich_text
	rich_text = $"../Day Counter"
	rich_text.text = "Days: " + str(Data.day_count) 
	create_test_flight()



func _on_show_graph_button_down() -> int:
	
	var current_city = Data.Current_City
	var current_day = "day_"+str(Data.day_count)
	var city_day = Data.dict_names[current_day]
	
	if not city_day.has(current_city) or (Data.day_count <= 0):
		return -1
	var city_stats = city_day[current_city]["sir_history"]
	print(" SIR history: ",city_stats)
	
	# Update global variables
	Data.Current_S = city_stats[0]
	Data.Current_I = city_stats[1]
	Data.Current_R = city_stats[2]
	Data.Current_D = city_stats[3]

	print("Current S: ", Data.Current_S)
	print("Current I: ", Data.Current_I)
	print("Current R: ", Data.Current_R)
		
	get_tree().change_scene_to_file("res://scenes/plot.tscn")
	return 0
		

func _on_day_back_button_down() -> int:
	if Data.day_count <= 0: 
		print("Can't do that bro")
		return -1
	Data.day_count -= 1
	var rich_text
	rich_text = $"../Day Counter"
	
	rich_text.text = "Days: " + str(Data.day_count) 
	return 0
func create_test_flight() -> void:
	var buildings_node = get_node_or_null("/root/Main_Scene/buildings")
	
	if not buildings_node:
		var buildings_scene = load("res://scenes/buildings/buildings.tscn")
		buildings_node = buildings_scene.instantiate()
		add_child(buildings_node)
		print("Instantiated buildings scene")
	
	var airport_terminal = buildings_node.get_node_or_null("Airport_Terminal")
	
	if not airport_terminal:
		print("ERROR: Could not find Airport_Terminal within buildings node")
		return
	
	var current_day = "day_" + str(Data.day_count)
	if not Data.dict_names[current_day].has("movements"):
		print("No movement data for day: " + current_day)
		return
	
	var movements = Data.dict_names[current_day]["movements"][current_day]
	print("Found " + str(movements.size()) + " movements for " + current_day)
	
	var MAX_TOTAL_PLANES = 80  # Adjust this based on your system capabilities
	var MAX_PLANES_PER_ROUTE = 20 # Maximum planes between any two cities
	
	print("Phase 1: Planning flight routes...")
	var flight_data = []
	var total_planes = 0
	
	movements.sort_custom(func(a, b): return a.total > b.total)
	
	for movement in movements:
		var from_city = movement["from_city"]
		var to_city = movement["to_city"]
		var total = movement["total"]
		
		if total < 5000:
			continue
			
		var desired_planes = max(1, int(total / 6000))
		
		var num_planes = min(desired_planes, MAX_PLANES_PER_ROUTE)
		
		if total_planes + num_planes > MAX_TOTAL_PLANES:
			num_planes = max(0, MAX_TOTAL_PLANES - total_planes)
			if num_planes == 0:
				print("Skipping route " + from_city + "->" + to_city + " (hit plane cap)")
				continue
		
		total_planes += num_planes
		
		flight_data.append({
			"from": from_city,
			"to": to_city,
			"total": total,
			"planes": num_planes
		})
		
		print("Planned " + str(num_planes) + " flights from " + from_city + " to " + to_city)
		
		if total_planes >= MAX_TOTAL_PLANES:
			print("Hit maximum plane cap of " + str(MAX_TOTAL_PLANES))
			break
	
	print("Planning complete. Total planes: " + str(total_planes))
	
	print("Phase 2: Creating flight paths...")
	var terminals = []
	
	for flight in flight_data:
		for i in range(flight.planes):
			var new_terminal = airport_terminal.duplicate()
			new_terminal.name = "Terminal_" + flight.from + "_to_" + flight.to + "_" + str(i)
			new_terminal.debug_mode = false
			buildings_node.add_child(new_terminal)
			new_terminal.auto_start_flight = false
			new_terminal.plane_directions(flight.from, flight.to, 1.0)
			terminals.append(new_terminal)
		await get_tree().create_timer(0.05).timeout
	
	print("Phase 3: Starting all " + str(terminals.size()) + " flights...")
	for terminal in terminals:
		terminal.is_flight_active = true
		await get_tree().create_timer(0.05).timeout
	
	print("Phase 4: Waiting for flights to complete...")
	var completed_count = 0
	
	while completed_count < terminals.size():
		completed_count = 0
		for terminal in terminals:
			if terminal.flight_completed:
				completed_count += 1
		print(str(completed_count) + "/" + str(terminals.size()) + " flights completed")
		
		await get_tree().create_timer(1.0).timeout
	
	for terminal in terminals:
		terminal.queue_free()
	
	print("All flights for day " + current_day + " completed")
# Helper function to print the scene hierarchy
func print_node_hierarchy(node, indent = "- "):
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_node_hierarchy(child, indent + "  ")
