extends RichTextLabel

func _ready() -> void:
	# Make background transparent
	add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var style = get_theme_stylebox("normal")
	if style is StyleBoxFlat:
		style.bg_color = Color(0, 0, 0, 0)
		style.set_corner_radius_all(0)
		# Fix for Godot 4 - use border_width_bottom/left/right/top instead of border_width_all
		style.border_width_bottom = 0
		style.border_width_left = 0
		style.border_width_right = 0
		style.border_width_top = 0
	
	bbcode_enabled = true
	
	# Set initial text
	text = "[b]Virus:[/b] None detected"
	
	# Start updating after a short delay
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	update_virus_info()

func _process(_delta: float) -> void:
	# Update periodically
	update_virus_info()

func update_virus_info() -> void:
	var current_day_key = "day_" + str(Data.day_count)
	
	# Check if we have data for the current day
	if !Data.dict_names.has(current_day_key):
		return  # Keep showing previous info
	
	# Check if virus history exists for the current day
	if !Data.dict_names[current_day_key].has("virus_history") or !Data.dict_names[current_day_key]["virus_history"].has(current_day_key):
		text = "[b]Virus:[/b] None detected"
		return
	
	var virus_data = Data.dict_names[current_day_key]["virus_history"][current_day_key]
	
	if !virus_data or !virus_data.has("current_strain") or !virus_data.has("strains"):
		text = "[b]Virus:[/b] No data available"
		return
	
	var current_strain = virus_data["current_strain"]
	var strain_data = virus_data["strains"][current_strain]
	
	var output = "[b]Virus:[/b] %s\n" % current_strain
	output += "[b]Transmission:[/b] %s\n" % strain_data["attributes"]["transmission_mode"]
	output += "[b]Infection Rate:[/b] %.3f\n" % strain_data["infection_rate"]
	output += "[b]Recovery Rate:[/b] %.3f\n" % strain_data["recovery_rate"]
	output += "[b]Lethality:[/b] %.2f%%\n" % (strain_data["lethality"] * 100)
	
	# Add mutation information if available
	if virus_data.has("mutation_rate"):
		output += "[b]Mutation Rate:[/b] %.4f" % virus_data["mutation_rate"]
	
	# Add other attributes if available
	if strain_data["attributes"].has("incubation_period"):
		output += "\n[b]Incubation:[/b] %d days" % strain_data["attributes"]["incubation_period"]
	
	if strain_data["attributes"].has("symptom_severity"):
		output += "\n[b]Severity:[/b] %d/10" % strain_data["attributes"]["symptom_severity"]
	
	text = output
