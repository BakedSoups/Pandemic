import numpy as np
import json
from step import step_function, get_travel_durations
import os
from scipy.special import softmax
import copy

# Get the current working directory
directory = os.getcwd()
# change to empty this out when testing python version
# mode = directory + "/Python_Brain/"
mode = ""

def configure_virus(config=None):
    """
    Create a virus configuration based on provided parameters
    
    Parameters:
    - config: Dictionary with virus parameters
    
    Returns:
    - Complete virus configuration dictionary
    """
    # Default virus configuration
    default_virus = {
        "current_strain": "original",
        "strains": {
            "original": {
                "parent": None,
                "emergence_day": 0,
                "infection_rate": 0.9,
                "recovery_rate": 0.4,
                "lethality": 0.01,  # 1% mortality
                "attributes": {
                    "transmission_mode": "droplet",
                    "incubation_period": 5,
                    "symptom_severity": 5  # 1-10 scale
                }
            }
        },
        "infection_rate": 0.9,
        "recovery_rate": 0.4,
        "lethality": 0.01,
        "mutation_rate": 0.002,
        "attributes": {
            "transmission_mode": "droplet",
            "incubation_period": 5,
            "symptom_severity": 5
        }
    }
    
    # If no config provided, return default
    if config is None:
        return default_virus
    
    # If config provided, update default values
    virus = copy.deepcopy(default_virus)
    
    # Update basic properties
    if "infection_rate" in config:
        virus["infection_rate"] = config["infection_rate"]
        virus["strains"]["original"]["infection_rate"] = config["infection_rate"]
    
    if "recovery_rate" in config:
        virus["recovery_rate"] = config["recovery_rate"]
        virus["strains"]["original"]["recovery_rate"] = config["recovery_rate"]
    
    if "lethality" in config:
        virus["lethality"] = config["lethality"]
        virus["strains"]["original"]["lethality"] = config["lethality"]
    
    if "mutation_rate" in config:
        virus["mutation_rate"] = config["mutation_rate"]
    
    # Update attributes
    if "attributes" in config:
        for key, value in config["attributes"].items():
            if key in virus["attributes"]:
                virus["attributes"][key] = value
                virus["strains"]["original"]["attributes"][key] = value
    
    return virus

def add_day(state_dictionary, city_dictionary, city_array):
    """
    Add a simulation day with enhanced virus model support
    """
    sir_matrix = np.array(state_dictionary["vector"])
    
    if sir_matrix.shape[1] == 3:  # SIR format
        death_column = np.zeros((sir_matrix.shape[0], 1))
        sird_matrix = np.hstack((sir_matrix, death_column))
        state_dictionary["vector"] = sird_matrix.tolist()
    else:
        sird_matrix = sir_matrix
    
    markov_matrix = np.array(state_dictionary["matrix"])
    
    virus = state_dictionary.get("virus", None)
    if virus is None:
        virus = configure_virus({
            "infection_rate": state_dictionary.get("infection_rate", 0.9),
            "recovery_rate": state_dictionary.get("recovery_rate", 0.4)
        })
        state_dictionary["virus"] = virus
    
    a = virus["infection_rate"]
    b = virus["recovery_rate"]
    
    city_names = [city["name"] for city in city_array]
    
    current_day = len(city_dictionary[city_array[0]["name"]]["sir_history"][0])
    day_key = f"day_{current_day}"
    
    in_transit = city_dictionary.get("in_transit", [])
    
    result = step_function(sird_matrix, markov_matrix, a, b, city_names, current_day, in_transit, virus)
    
    if isinstance(result, tuple) and len(result) >= 5:
        if len(result) == 6:
            sird_matrix, movement_data, city_exodus, updated_in_transit, arrivals, updated_virus = result
            state_dictionary["virus"] = updated_virus
        else:
            sird_matrix, movement_data, city_exodus, updated_in_transit, arrivals = result
    else:
        sird_matrix = result
        movement_data = []
        city_exodus = {}
        updated_in_transit = []
        arrivals = {}
    
    state_dictionary["vector"] = sird_matrix.tolist()
    
    city_dictionary["in_transit"] = updated_in_transit
    
    if "movements" not in city_dictionary:
        city_dictionary["movements"] = {}
    
    city_dictionary["movements"][day_key] = movement_data
    
    for city_name in city_names:
        if "exodus_history" not in city_dictionary[city_name]:
            city_dictionary[city_name]["exodus_history"] = {}
            
        if city_name in city_exodus:
            city_dictionary[city_name]["exodus_history"][day_key] = city_exodus[city_name]["left_for"]
        else:
            city_dictionary[city_name]["exodus_history"][day_key] = {}
        
        if "arrivals_history" not in city_dictionary[city_name]:
            city_dictionary[city_name]["arrivals_history"] = {}
        
        if city_name in arrivals:
            city_dictionary[city_name]["arrivals_history"][day_key] = arrivals[city_name]
        else:
            city_dictionary[city_name]["arrivals_history"][day_key] = {}
    
    N = len(city_array)
    for i in range(N):
        city_name = city_array[i]["name"]
        
        if len(city_dictionary[city_name]["sir_history"]) == 3:
            city_dictionary[city_name]["sir_history"].append([0.0])
        
        city_dictionary[city_name]["sir_history"][0].append(float(sird_matrix[i][0]))  # S
        city_dictionary[city_name]["sir_history"][1].append(float(sird_matrix[i][1]))  # I
        city_dictionary[city_name]["sir_history"][2].append(float(sird_matrix[i][2]))  # R
        
        if sird_matrix.shape[1] > 3:
            city_dictionary[city_name]["sir_history"][3].append(float(sird_matrix[i][3]))  # D
    
    if "virus_history" not in city_dictionary:
        city_dictionary["virus_history"] = {}
    
    if "virus" in state_dictionary:
        city_dictionary["virus_history"][day_key] = {
            "current_strain": state_dictionary["virus"]["current_strain"],
            "strains": copy.deepcopy(state_dictionary["virus"]["strains"]),
            "mutation_rate": state_dictionary["virus"]["mutation_rate"]
        }
    
    return city_dictionary

def start_pandemic(seed, state_dictionary, city_array, virus_config=None):
    """
    Initialize pandemic simulation with enhanced virus model and improved travel distribution
    """
    # configure virus and basic parameters
    virus = configure_virus(virus_config)
    state_dictionary["virus"] = virus
    
    infection_rate = virus["infection_rate"]
    recovery_rate = virus["recovery_rate"]
    state_dictionary["infection_rate"] = infection_rate
    state_dictionary["recovery_rate"] = recovery_rate
    
    N = len(city_array)
    
    # initialize SIRD matrix
    sird_matrix = []
    for i in range(N):
        res = 0
        if city_array[i]["name"] == seed:
            res = 1
        sird_matrix.append([city_array[i]["population"] - res, res, 0, 0])
    
    # create a more balanced markov matrix using population and distance factors
    markov_matrix = np.eye(N)  # start with identity matrix (staying in place)
    
    # calculate distances between cities
    distances = np.zeros((N, N))
    for i in range(N):
        for j in range(N):
            if i != j:
                # simple euclidean distance between city coordinates
                lat1, lon1 = city_array[i]["latitude"], city_array[i]["longitude"]
                lat2, lon2 = city_array[j]["latitude"], city_array[j]["longitude"]
                distances[i][j] = np.sqrt((lat1 - lat2)**2 + (lon1 - lon2)**2)
    
    # normalize distances
    max_dist = np.max(distances)
    if max_dist > 0:
        norm_distances = distances / max_dist
    else:
        norm_distances = distances
    
    # create transition probabilities based on population and distance
    for i in range(N):  # from city
        for j in range(N):  # to city
            if i != j:
                # probability based on destination population (attractive factor)
                pop_factor = city_array[j]["population"] / 10000000  # normalize large populations
                
                # inverse distance factor (closer = more likely)
                dist_factor = 0
                if norm_distances[i][j] > 0:
                    dist_factor = 1 / (1 + norm_distances[i][j])
                
                # combined factor with small random component
                travel_prob = 0.05 * pop_factor * dist_factor
                travel_prob += np.random.uniform(0, 0.01)  # small random variation
                
                markov_matrix[j][i] = travel_prob
    
    # normalize each column to create proper probability distribution
    # columns represent "from city", rows represent "to city"
    for i in range(N):
        markov_matrix[:, i] = markov_matrix[:, i] / np.sum(markov_matrix[:, i])
    
    state_dictionary["vector"] = sird_matrix
    state_dictionary["matrix"] = markov_matrix.tolist()
    
    # initialize city dictionary
    city_dictionary = {}
    for i in range(N):
        city_dictionary[city_array[i]["name"]] = {
            "sir_history": [
                [float(sird_matrix[i][0])],  # S
                [float(sird_matrix[i][1])],  # I
                [float(sird_matrix[i][2])],  # R
                [float(sird_matrix[i][3])]   # D
            ],
            "latitude": city_array[i]["latitude"],
            "longitude": city_array[i]["longitude"]
        }
    
    city_dictionary["movements"] = {"day_0": []}
    city_dictionary["in_transit"] = []
    
    city_dictionary["virus_history"] = {
        "day_0": {
            "current_strain": virus["current_strain"],
            "strains": copy.deepcopy(virus["strains"]),
            "mutation_rate": virus["mutation_rate"]
        }
    }
    
    for city_name in [city["name"] for city in city_array]:
        city_dictionary[city_name]["exodus_history"] = {"day_0": {}}
        city_dictionary[city_name]["arrivals_history"] = {"day_0": {}}
    
    return state_dictionary, city_dictionary

def get_travel_durations():
    """Define more balanced travel durations between cities in days."""
    return {
        "SF": {"NYC": 4, "WA": 5, "CHI": 3, "PA": 3, "LON": 9, "MA": 6},
        "NYC": {"SF": 4, "WA": 3, "CHI": 2, "PA": 1, "LON": 7, "MA": 8},
        "WA": {"SF": 5, "NYC": 3, "CHI": 3, "PA": 2, "LON": 8, "MA": 7},
        "CHI": {"SF": 3, "NYC": 2, "WA": 3, "PA": 1, "LON": 7, "MA": 6},
        "PA": {"SF": 3, "NYC": 1, "WA": 2, "CHI": 1, "LON": 6, "MA": 5},
        "LON": {"SF": 9, "NYC": 7, "WA": 8, "CHI": 7, "PA": 6, "MA": 10},
        "MA": {"SF": 6, "NYC": 8, "WA": 7, "CHI": 6, "PA": 5, "LON": 10}
    }

def track_movement(sir_matrix, markov_matrix, city_names, max_workers=None):
    """Improved movement tracking that ensures more balanced flight distribution"""
    moved_matrix = markov_matrix @ sir_matrix
    
    # process each city pair
    movement_data = []
    
    for i in range(len(sir_matrix)):
        for j in range(len(sir_matrix)):
            from_city = city_names[i]
            to_city = city_names[j]
            
            if i == j or markov_matrix[j][i] == 0:
                continue
            
            s_source, i_source, r_source = sir_matrix[i][:3]
            
            # transition probability from city i to city j
            transition_prob = markov_matrix[j][i]
            
            # ensure minimum movement threshold for better distribution
            s_moved = max(1, int(s_source * transition_prob))
            i_moved = max(0, int(i_source * transition_prob))
            r_moved = max(0, int(r_source * transition_prob))
            
            # only record meaningful movement
            if s_moved + i_moved + r_moved > 0:
                movement_data.append({
                    "from_city": from_city,
                    "to_city": to_city,
                    "s_count": s_moved,
                    "i_count": i_moved,
                    "r_count": r_moved,
                    "total": s_moved + i_moved + r_moved
                })
    
    return moved_matrix, movement_data

# make sure to include this in your simulation.py file
# and update the city array in preload.py to have unique coordinates for MA
    """
    Initialize pandemic simulation with enhanced virus model
    """
    def softmax(x):
        exp_x = np.exp(x - np.max(x))
        return exp_x / np.sum(exp_x)
    
    virus = configure_virus(virus_config)
    state_dictionary["virus"] = virus
    
    infection_rate = virus["infection_rate"]
    recovery_rate = virus["recovery_rate"]
    state_dictionary["infection_rate"] = infection_rate
    state_dictionary["recovery_rate"] = recovery_rate
    
    travel_factor = 0.1
    N = len(city_array)
    
    sird_matrix = []
    for i in range(N):
        res = 0
        if city_array[i]["name"] == seed:
            res = 1
        sird_matrix.append([city_array[i]["population"] - res, res, 0, 0])  # Added D=0
    
    markov_matrix = travel_factor*np.random.rand(N, N) + 5*np.eye(N)
    markov_matrix = np.apply_along_axis(softmax, axis=0, arr=markov_matrix)
    
    state_dictionary["vector"] = sird_matrix
    state_dictionary["matrix"] = markov_matrix.tolist()
    
    city_dictionary = {}
    for i in range(N):
        city_dictionary[city_array[i]["name"]] = {
            "sir_history": [
                [float(sird_matrix[i][0])],  # S
                [float(sird_matrix[i][1])],  # I
                [float(sird_matrix[i][2])],  # R
                [float(sird_matrix[i][3])]   # D
            ],
            "latitude": city_array[i]["latitude"],
            "longitude": city_array[i]["longitude"]
        }
    
    city_dictionary["movements"] = {"day_0": []}
    
    city_dictionary["in_transit"] = []
    
    city_dictionary["virus_history"] = {
        "day_0": {
            "current_strain": virus["current_strain"],
            "strains": copy.deepcopy(virus["strains"]),
            "mutation_rate": virus["mutation_rate"]
        }
    }
    
    for city_name in [city["name"] for city in city_array]:
        city_dictionary[city_name]["exodus_history"] = {"day_0": {}}
        city_dictionary[city_name]["arrivals_history"] = {"day_0": {}}
    
    return state_dictionary, city_dictionary