extends Node2D
var CircleScene = preload("res://circle.tscn")

var Circle

## Assuming rate of infection and recovery rate for graphs
var GAMMA = 0.6
var BETA = 0.4
var DELTA = 0.2  # Death rate parameter

## Global Colors
var cb = Color(0, 0, 0)
var cg = Color(0, 1, 0)
var cr = Color(1, 0, 0)
var cbl = Color(0, 0, 1)
var cgl = Color(0, 1, 0, 0.05)
var crl = Color(1, 0, 0, 0.15)
var cbll = Color(0, 0, 1, 0.15)
var cp = Color(0.5, 0, 0.5)  # Purple color for death data
var cpl = Color(0.5, 0, 0.5, 0.15)  # Light purple for simulated death data

## Global lines
var line_S : Line2D
var line_I : Line2D
var line_R : Line2D
var line_D : Line2D  # New line for death data
var axis_X : Line2D
var axis_Y : Line2D
var line_Sa : Line2D
var line_Ia : Line2D
var line_Ra : Line2D
var line_Da : Line2D  # New line for simulated death data
var line_width = 2


## Fetch city data
var read_S = Data.Current_S
var read_I = Data.Current_I
var read_R = Data.Current_R
var read_D = Data.Current_D  # New death data

var max_og = max(read_S.max(), read_I.max(), read_R.max(), read_D.max())

## Normalize data 
var S = normalize(read_S)
var I = normalize(read_I)
var R = normalize(read_R)
var D = normalize(read_D)  # Normalize death data

var max_value = max(S.max(), I.max(), R.max(), D.max())

var N = get_N()
var T = max(len(S), len(I), len(R), len(D))

## Graph Dimensions
var l_margin = 50
var top_margin = 25
var dim = 350  # Fixed size for graph regardless of time range
var width = max_value + 50
var scale_factor_y = (dim - top_margin) / max_value
var scale_factor_x = (dim - l_margin) / T

func format_abbreviated_number(value: int) -> String:
	if value >= 1_000_000_000:
		return str(round(value / 1_000_000_000.0 * 10) / 10.0) + "b"
	elif value >= 1_000_000:
		return str(round(value / 1_000_000.0 * 10) / 10.0) + "m"
	elif value >= 1_000:
		return str(round(value / 1_000.0 * 10) / 10.0) + "k"
	else:
		return str(value)
func update_graph():
	read_S = Data.Current_S
	read_I = Data.Current_I
	read_R = Data.Current_R
	read_D = Data.Current_D

	print("ACTIVATED", read_S, read_I, read_R, read_D)

	max_og = max(read_S.max(), read_I.max(), read_R.max(), read_D.max())

	S = normalize(read_S)
	I = normalize(read_I)
	R = normalize(read_R)
	D = normalize(read_D)

	max_value = max(S.max(), I.max(), R.max(), D.max())
	T = max(len(S), len(I), len(R), len(D))
	N = get_N()

	scale_factor_y = (dim - top_margin) / max_value
	scale_factor_x = (dim - l_margin) / T

	draw_axis()
	plot_actual()
	plot_model(BETA, GAMMA, DELTA)
## Normalizing function to prevent larger ranges from dominating the screen
func normalize(arr: Array) -> Array:
	var scaled_values = []
	for value in arr:
		var power_of_10 = ceil(log(max_og) / log(10)) 
		scaled_values.append(value / 10 ** power_of_10)
		
	return scaled_values

func get_N():
	var max_combination = 0
	for i in range(len(S)):
		var current_combination = S[i] + I[i] + R[i] + D[i]  # Include D in total
		if current_combination > max_combination:
			max_combination = current_combination
	return max_combination
	
## Differential Equation Logic
func deriv(y, t, N, beta, gamma, delta) -> Array:
	var SA = y[0]
	var IA = y[1]
	var RA = y[2]
	var DA = y[3]  # Death compartment
	
	var dSdt = -gamma * SA * IA / N  
	var dIdt = (gamma * SA * IA / N) - beta * IA - delta * IA  # Infected can now die
	var dRdt = beta * IA  
	var dDdt = delta * IA  # Death rate equation
	
	return [dSdt, dIdt, dRdt, dDdt]
	
## Step function to plot differential equations
func plot_model(beta, gamma, delta):
	var line_SA = Line2D.new()
	line_SA.default_color = cbll
	add_child(line_SA)
	
	var line_IA = Line2D.new()
	line_IA.default_color = crl
	add_child(line_IA)
	
	var line_RA = Line2D.new()
	line_RA.default_color = cgl
	add_child(line_RA)
	
	var line_DA = Line2D.new()  # New line for simulated death data
	line_DA.default_color = cpl
	add_child(line_DA)
	
	var S_sim = [S[0]]  
	var I_sim = [I[0]]  
	var R_sim = [R[0]]
	var D_sim = [D[0]]  # Initialize with first death data point
	var dt = 4
	for t in range(T):
		var dydt = deriv([S_sim[t], I_sim[t], R_sim[t], D_sim[t]], t, N, beta, gamma, delta)
		var next_S = S_sim[t] + dydt[0] * dt
		var next_I = I_sim[t] + dydt[1] * dt
		var next_R = R_sim[t] + dydt[2] * dt
		var next_D = D_sim[t] + dydt[3] * dt  # Calculate next death value
		
		S_sim.append(next_S)
		I_sim.append(next_I)
		R_sim.append(next_R)
		D_sim.append(next_D)  # Add to death simulation array
	
	plot_vector(S_sim, cbll, line_SA)
	plot_vector(I_sim, crl, line_IA)
	plot_vector(R_sim, cgl, line_RA)
	plot_vector(D_sim, cpl, line_DA)  # Plot death simulation


## Axis Logic
func draw_axis():
	
	axis_X = Line2D.new()
	axis_X.width = 5
	axis_X.default_color = cb
	axis_X.add_point(Vector2(l_margin, top_margin + dim))
	axis_X.add_point(Vector2(l_margin + dim, top_margin + dim))  # Fixed width axis
	add_child(axis_X)

	axis_Y = Line2D.new()
	axis_Y.width = 5
	axis_Y.default_color = cb
	axis_Y.add_point(Vector2(l_margin, top_margin + dim))
	axis_Y.add_point(Vector2(l_margin, top_margin))
	add_child(axis_Y)

	## Axis ticks and Tick Labels
	for i in range(0, 10): 
		var tick_pos = top_margin + (dim - i * (dim / 10))
		var tick = Line2D.new()
		tick.width = 1
		tick.default_color = cb
		tick.add_point(Vector2(l_margin - 5, tick_pos))
		tick.add_point(Vector2(l_margin + 5, tick_pos))
		add_child(tick)

		var label = Label.new()
		# Convert to integer instead of decimal
		label.text = format_abbreviated_number(int(i * (max_og / 10)))
		label.position = Vector2(l_margin - 70, tick_pos - 5)
		label.z_index = -1  # Place behind the bar
		add_child(label)


	var max_ticks = 10  # Maximum number of ticks to show
	var step = max(1, int(T / max_ticks))  # Calculate step size based on data length
	
	for i in range(0, T, step):
		var tick_pos = l_margin + (i * scale_factor_x)
		var tick = Line2D.new()
		tick.width = 1
		tick.default_color = cb
		tick.add_point(Vector2(tick_pos, top_margin + dim - 5))
		tick.add_point(Vector2(tick_pos, top_margin + dim + 5))
		add_child(tick)

		var label = Label.new()
		label.text = str(i)
		label.position = Vector2(tick_pos - 5, top_margin + dim + 10)
		add_child(label)	

	## Title and Graph Labels
	var title = Label.new()
	title.text = "SIRD Model"  # Updated title to reflect death variable
	title.position = Vector2(l_margin, top_margin - 50)
	add_child(title)
	
	var x_label = Label.new()
	x_label.text = "Time (Days)"
	x_label.position = Vector2((l_margin + (T * scale_factor_x)) / 2, top_margin + dim + 40)
	add_child(x_label)

	var y_label = Label.new()
	y_label.rotation_degrees = -90
	y_label.text = "Population"
	y_label.position = Vector2(l_margin - 90, top_margin + dim / 2)
	add_child(y_label)
	
	var og = Label.new()
	og.text = "**Original Scaling:     "  + str(int(max_og))
	og.position = Vector2(l_margin, top_margin + dim + 100)
	add_child(og)

func plot_vector_points(vector : Array, vector2 : Array, color : Color, line : Line2D, name: String):

	## Animation logic
	var tween = create_tween()
	line.width = 2.5

	for i in range(vector.size()):

		var x_pos = l_margin + i * scale_factor_x
		var y_pos = top_margin + (dim - (vector[i] * scale_factor_y))
		line.add_point(Vector2(x_pos, y_pos))	

		tween.tween_property(line, "points", line.points, 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

		## Circle tooltips
		var circle_instance = CircleScene.instantiate()
		circle_instance.init(x_pos, y_pos, vector2[i])
		add_child(circle_instance)
		
	var x_pos = l_margin + vector.size() * scale_factor_x - 10
	var y_pos = top_margin + (dim - (vector[vector.size() - 1] * scale_factor_y)) - 30
	
	var label = Label.new()
	label.text = str(name)
	label.position = Vector2(x_pos, y_pos)
	add_child(label)
	
## For comparision we also plot the expected SIR based on specified gma and beta
func plot_actual():
	line_S = Line2D.new()
	line_S.default_color = cbl
	add_child(line_S)
	
	line_I = Line2D.new()
	line_I.default_color = cr
	add_child(line_I)
	
	line_R = Line2D.new()
	line_R.default_color = cg
	add_child(line_R)
	
	line_D = Line2D.new()  # New line for death data
	line_D.default_color = cp
	add_child(line_D)
	
	plot_vector_points(S, read_S, cbl, line_S, "dS/dT")
	plot_vector_points(I, read_I, cr, line_I, "dI/dT")
	plot_vector_points(R, read_R, cg, line_R, "dR/dT")
	plot_vector_points(D, read_D, cp, line_D, "dD/dT")  # Plot death data

func plot_vector(vector : Array, color : Color, line : Line2D):
	for i in range(vector.size()):
		var x_pos = l_margin + i * scale_factor_x
		var y_pos = top_margin + (dim - (vector[i] * scale_factor_y))
		line.width = line_width
		line.add_point(Vector2(x_pos, y_pos))


func _on_show_graph_button_down() -> void:
	# Initialize with fixed dimensions

	set_process(true)
		

	# Recalculate scale factors based on fixed dimensions
	scale_factor_y = (dim - top_margin) / max_value
	scale_factor_x = (dim - l_margin) / T
	
	draw_axis()
	plot_actual()
	plot_model(BETA, GAMMA, DELTA)
	print("ACTIVATED", S,I,R,D)
	
