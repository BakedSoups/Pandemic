extends RichTextLabel

func _ready() -> void:
	bbcode_enabled = true
	
	# Set initial values to zero
	var initial_text = "[b]S:[/b] 0\n"
	initial_text += "[b][color=#ff0000]I:[/color][/b] 0\n"
	initial_text += "[b][color=#00cc00]R:[/color][/b] 0\n"
	initial_text += "[b][color=#888888]D:[/color][/b] 0"
	
	text = initial_text
	
	# Start updating after a short delay
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	update_display()

func _process(_delta: float) -> void:
	# Update the display periodically
	update_display()

func update_display() -> void:
	var current_day_key = "day_" + str(Data.day_count)
	
	# Check if we have data for the current day
	if !Data.dict_names.has(current_day_key):
		return  # Keep showing previous values
	
	# Initialize counters for global statistics
	var total_susceptible = 0
	var total_infected = 0
	var total_recovered = 0
	var total_deaths = 0
	
	# Loop through all cities in the data
	for city_name in Data.dict_names[current_day_key]:
		# Skip non-city entries in the dictionary
		if typeof(Data.dict_names[current_day_key][city_name]) != TYPE_DICTIONARY:
			continue
			
		if !Data.dict_names[current_day_key][city_name].has("sir_history"):
			continue
			
		var sir_history = Data.dict_names[current_day_key][city_name]["sir_history"]
		
		# Skip if we don't have enough data
		if sir_history.size() < 3:
			continue
			
		# Get the day index
		var day_index = min(Data.day_count, sir_history[0].size() - 1)
		if day_index < 0 or day_index >= sir_history[0].size():
			continue
			
		# Add to global totals
		total_susceptible += sir_history[0][day_index]
		total_infected += sir_history[1][day_index]
		total_recovered += sir_history[2][day_index]
		
		# Add deaths if data exists
		if sir_history.size() > 3 and day_index < sir_history[3].size():
			total_deaths += sir_history[3][day_index]
	
	# Format the display text with bbcode for styling - just the SIRD values
	var output = "[b]S:[/b] %s\n" % format_number(total_susceptible)
	output += "[b][color=#ff0000]I:[/color][/b] %s\n" % format_number(total_infected)
	output += "[b][color=#00cc00]R:[/color][/b] %s\n" % format_number(total_recovered)
	output += "[b][color=#888888]D:[/color][/b] %s" % format_number(total_deaths)
	
	text = output

func format_number(number: float) -> String:
	var num_str = str(int(number))
	var result = ""
	var count = 0
	
	for i in range(num_str.length() - 1, -1, -1):
		result = num_str[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	
	return result
