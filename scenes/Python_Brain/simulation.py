import numpy as np
import json
from step import step_function
import os
from scipy.special import softmax

# Get the current working directory
directory = os.getcwd()
# change to empty this out when testing python version
# mode = directory + "/Python_Brain/"
mode = ""

def add_day(state_dictionary, city_dictionary, city_array):
    sir_matrix = np.array(state_dictionary["vector"])
    markov_matrix = np.array(state_dictionary["matrix"])
    a = state_dictionary["infection_rate"]
    b = state_dictionary["recovery_rate"]
    
    # get city names for movement tracking
    city_names = [city["name"] for city in city_array]
    
    # returns movement data and city exodus
    result = step_function(sir_matrix, markov_matrix, a, b, city_names)
    
    # unpack the result (new sir_matrix, movement_data, and city_exodus)
    if isinstance(result, tuple) and len(result) == 3:
        sir_matrix, movement_data, city_exodus = result
    elif isinstance(result, tuple) and len(result) == 2:
        sir_matrix, movement_data = result
        city_exodus = {}
    else:
        sir_matrix = result
        movement_data = []
        city_exodus = {}
    
    #  state vector
    state_dictionary["vector"] = sir_matrix.tolist()
    
    current_day = len(city_dictionary[city_array[0]["name"]]["sir_history"][0])
    day_key = f"day_{current_day}"
    
    if "movements" not in city_dictionary:
        city_dictionary["movements"] = {}
    
    city_dictionary["movements"][day_key] = movement_data
    
    for city_name in city_names:
        if "exodus_history" not in city_dictionary[city_name]:
            city_dictionary[city_name]["exodus_history"] = {}
            
        #storing the day exodus history into the city_name
        if city_name in city_exodus:
            city_dictionary[city_name]["exodus_history"][day_key] = city_exodus[city_name]["left_for"]
        else:
            city_dictionary[city_name]["exodus_history"][day_key] = {}
    
    # now update the sir from before
    N = len(city_array)
    for i in range(N):
        city_dictionary[city_array[i]["name"]]["sir_history"][0].append(float(sir_matrix[i][0]))
        city_dictionary[city_array[i]["name"]]["sir_history"][1].append(float(sir_matrix[i][1]))
        city_dictionary[city_array[i]["name"]]["sir_history"][2].append(float(sir_matrix[i][2]))
    
    return city_dictionary

def start_pandemic(seed, state_dictionary, city_array):
    def softmax(x):
        exp_x = np.exp(x - np.max(x))
        return exp_x / np.sum(exp_x)
        
    travel_factor = 0.1
    N = len(city_array)
    sir_matrix = []
    
    for i in range(N):
        res = 0
        if city_array[i]["name"] == seed:
            res = 1
        sir_matrix.append([city_array[i]["population"] - res, res, 0])
    
    markov_matrix = travel_factor*np.random.rand(N, N) + 5*np.eye(N)
    markov_matrix = np.apply_along_axis(softmax, axis=0, arr=markov_matrix)
    
    state_dictionary["vector"] = sir_matrix
    state_dictionary["matrix"] = markov_matrix.tolist()
    
    city_dictionary = {}
    for i in range(N):
        city_dictionary[city_array[i]["name"]] = {
            "sir_history": [[float(sir_matrix[i][0])], [float(sir_matrix[i][1])], [float(sir_matrix[i][2])]],
            "latitude": city_array[i]["latitude"],
            "longitude": city_array[i]["longitude"]
        }
    
    # initialize empty movements record
    city_dictionary["movements"] = {"day_0": []}
    
    # initialize exodus tracking for each city
    for city_name in [city["name"] for city in city_array]:
        city_dictionary[city_name]["exodus_history"] = {"day_0": {}}
    
    return state_dictionary, city_dictionary