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
	var json = JSON.new()
	var names = FileAccess.get_file_as_string("res://Python_Brain/pandemic_simulation.json")
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
	Data.day_count += 1
	var rich_text
	rich_text = $"../Day Counter"
	
	# Now update the text with your variable
	var health = 100
	rich_text.text = "Days: " + str(Data.day_count) 

func _on_show_graph_button_down() -> void:
	var current_city = Data.Current_City
	var city_stats = Data.dict_names["day_"+str(Data.day_count)][current_city]["sir_history"]
	print(" SIR history: ",city_stats)
	
	# Update global variables
	Data.Current_S = city_stats[0]
	Data.Current_I = city_stats[1]
	Data.Current_R = city_stats[2]

	print("Current S: ", Data.Current_S)
	print("Current I: ", Data.Current_I)
	print("Current R: ", Data.Current_R)
		#
		# Get the NYC data for day 10
#nyc_data = simulation_data["day_10"]["NYC"]
#
## Get the SIR values for day 10
## Remember that city_stats stores all days from 0 to current
#susceptible = nyc_data["city_stats"][0][10]  # S value on day 10
#infected = nyc_data["city_stats"][1][10]     # I value on day 10
#recovered = nyc_data["city_stats"][2][10]    # R value on day 10
	get_tree().change_scene_to_file("res://plot.tscn")

func _on_day_back_button_down() -> int:
	if Data.day_count <= 0: 
		print("Can't do that bro")
		return -1
	Data.day_count -= 1
	var rich_text
	rich_text = $"../Day Counter"
	
	# Now update the text with your variable
	var health = 100
	rich_text.text = "Days: " + str(Data.day_count) 
	return 0
