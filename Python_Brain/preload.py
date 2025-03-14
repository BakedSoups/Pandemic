from simulation import *
import pprint
import copy
# goal is to create a prerendered json of all the days incrementally


class SIR_Simulation_Paramaters:
    def __init__(self):
        self.state = {
            "vector": [[808987, 1, 0], [8258000, 0, 0], [455924, 0, 0], [2664000, 0, 0], [2103000, 0, 0], [8866000, 0, 0], [8866000, 0, 0]],
            "infection_rate": 0.9,
            "recovery_rate": 0.4,
            "matrix": None
        }
        self.cities = [
            {"name": "SF", "population": 808988, "latitude": 37.795, "longitude": -122.419},
            {"name": "NYC", "population": 8258000, "latitude": 40.71, "longitude": -74.006},
            {"name": "WA", "population": 455924, "latitude": 25.7617, "longitude": -80.1918},
            {"name": "CHI", "population": 2664000, "latitude": 41.8781, "longitude": -87.6298},
            {"name": "PA", "population": 2103000, "latitude": 41.8781, "longitude": -87.6298},
            {"name": "LON", "population": 8866000, "latitude": 41.8781, "longitude": -87.6298},
            {"name": "MA", "population": 8866000, "latitude": 41.8781, "longitude": -87.6298}
        ]

books = SIR_Simulation_Paramaters()

state_dictionary = books.state
city_array = books.cities

seed = "SF"
# city_dictionary = cities.json, Cities, sir History, Matrix of SIR (this is the main infromation we need)
# state_dictionary = calculate the way SIR spreads 
# city_array = the cities and their initial populations, and locations (latitude, longitde)
state_dictionary, city_dictionary = start_pandemic(seed, state_dictionary, city_array)

# if the variables are still unclear just look at it here: 
# print(f"state_dictionary {state_dictionary} \ncity_dictionary {city_dictionary} \ncity_array: {city_array}\n")

preloaded = {}
# print("preloading simulation")
# store the first day
preloaded["day_0"] = copy.deepcopy(city_dictionary) 
pandemic_SIR_status = city_dictionary

for i in range(1,50):
    pandemic_SIR_status = add_day(state_dictionary,pandemic_SIR_status, city_array)
    preloaded[f"day_{i}"] = copy.deepcopy(pandemic_SIR_status)
# pprint.pprint(preloaded)

with open("pandemic_simulation.json", "w") as json_file:
    json.dump(preloaded, json_file, indent=4)

# print(json.dumps(preloaded))
# sys.stdout.flush() 