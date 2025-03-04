extends Node2D
var DIR = OS.get_executable_path().get_base_dir()
var interpreter_path = "res://Python_Brain/venv/bin/python3"
var script_path = "res://Python_Brain/evolve.py"
var script_path2 = "res://Python_Brain/init.py"
# Called when the node enters the scene tree for the first time.
func _ready():
	if !OS.has_feature("standalone"): # if NOT exported version
		interpreter_path = ProjectSettings.globalize_path("res://Python_Brain/venv/bin/python3.12")
		script_path = ProjectSettings.globalize_path("res://Python_Brain/evolve.py")
		script_path2 = ProjectSettings.globalize_path("res://Python_Brain/init.py")
	notify("Godot", "Ready", "Godot is initialized!")

func notify(title="", subtitle="", body=""):
	var output = []
	var exit_code = OS.execute(interpreter_path, [script_path2, title, subtitle, body], output, true)
	print("Exit code: ", exit_code)
	print("Output: ", output)
	

func run_step(title="", subtitle="", body=""):
	var output = []
	var exit_code = OS.execute(interpreter_path, [script_path, title, subtitle, body], output, true)
	var json = JSON.new()
	var names = FileAccess.get_file_as_string("res://Python_Brain/cities.json")
	var dict_names = JSON.parse_string(names)
	print("Exit code: ", exit_code)
	print("Output: ", output)
	
	Data.dict_names = dict_names
	
	
#save into a global dictionary

func _process(delta: float) -> void:
	pass
		
func _on_start_simulation_button_down() -> void:
	print("Starting simulation...")
	notify("Simulation", "Started", "The simulation has begun!")

func _on_day_add_button_down() -> void:
	run_step("Simulation", "Next Day", "Moving to the next day in simulation.")
	Data.day_count += 1
	var rich_text
	rich_text = $"../Day Counter"
	
	# Now update the text with your variable
	var health = 100
	rich_text.text = "Days: " + str(Data.day_count) 

func _on_show_graph_button_down() -> void:
	var current_city = Data.Current_City
	if Data.dict_names.has(current_city):
		var sir_history = Data.dict_names[current_city]["sir_history"]
		print(current_city," SIR history: ", sir_history)

		# Update your global variables
		Data.Current_S = sir_history[0]
		Data.Current_I = sir_history[1]
		Data.Current_R = sir_history[2]

		# Print them to verify
		print("Current S: ", Data.Current_S)
		print("Current I: ", Data.Current_I)
		print("Current R: ", Data.Current_R)
	get_tree().change_scene_to_file("res://plot.tscn")
