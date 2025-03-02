extends Node2D
var CircleScene = preload("res://circle.tscn")

var Circle

## Assuming rate of infection and recovery rate for graphs
var GAMMA = 0.6
var BETA = 0.4

## Global Colors
var cb = Color(0, 0, 0)
var cg = Color(0, 1, 0)
var cr = Color(1, 0, 0)
var cbl = Color(0, 0, 1)
var cgl = Color(0, 1, 0, 0.05)
var crl = Color(1, 0, 0, 0.15)
var cbll = Color(0, 0, 1, 0.15)

## Global lines
var line_S : Line2D
var line_I : Line2D
var line_R : Line2D
var axis_X : Line2D
var axis_Y : Line2D
var line_Sa : Line2D
var line_Ia : Line2D
var line_Ra : Line2D
var line_width = 2


## Fetch city data
var read_S = [90.0, 44.0, 43.0, 41.0, 40.0, 38.0, 36.0, 33.0, 30.0, 27.0, 10.0, 9.0, 8.0, 7.0]
var read_I = [1.0, 6.0, 7.0, 8.0, 9.0, 10.0, 10.0, 9.0, 7.0, 5.0, 3.0, 2.0, 1.0, 0.0]
var read_R = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 10.0, 15.0, 16.0, 18.0, 20.0]

var max_og = max(read_S.max(), read_I.max(), read_R.max())

## Normalize data 
var S = normalize(read_S)
var I = normalize(read_I)
var R = normalize(read_R)

var max_value = max(S.max(), I.max(), R.max())

var N = get_N()
var T = max(len(S), len(I),len(R))

## Graph Dimensions
var l_margin = 100
var top_margin = 50
var dim = T * 50
var width = max_value + 50
var scale_factor_y = (dim - top_margin) / max_value
var scale_factor_x = (dim - l_margin) / T


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
		var current_combination = S[i] + I[i] + R[i]
		if current_combination > max_combination:
			max_combination = current_combination
	return max_combination
	
## Differential Equation Logic
func deriv(y, t, N, beta, gamma) -> Array:
	var SA = y[0]
	var IA = y[1]
	var RA = y[2]
	
	var dSdt = -gamma * SA * IA / N  
	var dIdt = (gamma * SA * IA / N) - beta * IA 
	var dRdt = beta * IA  
	
	return [dSdt, dIdt, dRdt]
	
## Step function to plot differential equations
func plot_model(beta, gamma):
	var line_SA = Line2D.new()
	line_SA.default_color = cbll
	add_child(line_SA)
	
	var line_IA = Line2D.new()
	line_IA.default_color = crl
	add_child(line_IA)
	
	var line_RA = Line2D.new()
	line_RA.default_color = cgl
	add_child(line_RA)
	
	var S_sim = [S[0]]  
	var I_sim = [I[0]]  
	var R_sim = [R[0]] 
	var dt = 4
	for t in range(T):
		var dydt = deriv([S_sim[t], I_sim[t], R_sim[t]], t, N, beta, gamma)
		var next_S = S_sim[t] + dydt[0] * dt
		var next_I = I_sim[t] + dydt[1] * dt
		var next_R = R_sim[t] + dydt[2] * dt
		
		S_sim.append(next_S)
		I_sim.append(next_I)
		R_sim.append(next_R)
	
	plot_vector(S_sim, cbll, line_SA)
	plot_vector(I_sim, crl, line_IA)
	plot_vector(R_sim, cgl, line_RA)


## Axis Logic
func draw_axis():
	
	axis_X = Line2D.new()
	axis_X.width = 5
	axis_X.default_color = cb
	axis_X.add_point(Vector2(l_margin, top_margin + dim))
	axis_X.add_point(Vector2(l_margin + (T * scale_factor_x), top_margin + dim))
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
		label.text = str(i * (max_value / 10)) 
		label.position = Vector2(l_margin - 40, tick_pos - 5)
		add_child(label)


	for i in range(0, T):
		var tick_pos = l_margin + i * scale_factor_x
		var tick = Line2D.new()
		tick.width = 1
		tick.default_color = cb
		tick.add_point(Vector2(tick_pos, top_margin + dim - 5))
		tick.add_point(Vector2(tick_pos, top_margin + dim + 5))
		add_child(tick)

		var label = Label.new()
		label.text = str(i)
		label.position = Vector2(tick_pos + 5, top_margin + dim + 10)
		add_child(label)	

	## Title and Graph Labels
	var title = Label.new()
	title.text = "SIR Model"
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
	og.text = "**Original Scaling:     "  + str(max_og)
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
	
	plot_vector_points(S, read_S, cbl, line_S, "dS/dT")
	plot_vector_points(I, read_I, cr, line_I, "dI/dT")
	plot_vector_points(R, read_R, cg, line_R, "dR/dT")

func plot_vector(vector : Array, color : Color, line : Line2D):
	for i in range(vector.size()):
		var x_pos = l_margin + i * scale_factor_x
		var y_pos = top_margin + (dim - (vector[i] * scale_factor_y))
		line.width = line_width
		line.add_point(Vector2(x_pos, y_pos))


func _ready():
	draw_axis()
	plot_actual()
	plot_model(BETA, GAMMA)
