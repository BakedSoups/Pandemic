extends Node

# This is the dictionary with all city data
var dict_names: Dictionary = {
	"SF": { 
		"sir_history": [[808987, 885378], [1, 2], [0, 2]], 
		"latitude": 37.795, 
		"longitude": -122.419 
	},
	"NYC": { 
		"sir_history": [[8258000, 8094963], [0, 0], [0, 0]], 
		"latitude": 40.71, 
		"longitude": -74.006 
	},
	"LA": { 
		"sir_history": [[3280000, 3270737], [0, 0], [0, 0]], 
		"latitude": 34.0549, 
		"longitude": -118.2426 
	},
	"Miami": { 
		"sir_history": [[455924, 542824], [0, 0], [0, 0]], 
		"latitude": 25.7617, 
		"longitude": -80.1918 
	},
	"Chicago": { 
		"sir_history": [[2664000, 2673006], [0, 0], [0, 0]], 
		"latitude": 41.8781, 
		"longitude": -87.6298 
	}
}

var day_count: int = 0
var Current_S = [0]
var Current_I = [0]
var Current_R = [0]
var Current_City = "none"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _diagnostics() -> void: 
	print(dict_names)
	print(typeof(dict_names))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
