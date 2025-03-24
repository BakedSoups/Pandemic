from simulation import *
import pprint
import copy
import json


class SIR_Simulation_Parameters:
    def __init__(self):
        self.state = {
            "vector": [[808987, 1, 0, 0], [8258000, 0, 0, 0], [455924, 0, 0, 0], 
                      [2664000, 0, 0, 0], [2103000, 0, 0, 0], [8866000, 0, 0, 0], 
                      [8866000, 0, 0, 0]],
            "infection_rate": 0.9,
            "recovery_rate": 0.4,
            "matrix": None
        }
        self.cities = [
            {"name": "SF", "population": 808988, "latitude": 37.7749, "longitude": -122.4194},  # San Francisco
            {"name": "NYC", "population": 8258000, "latitude": 40.7128, "longitude": -74.0060},  # New York
            {"name": "WA", "population": 455924, "latitude": 38.9072, "longitude": -77.0369},    # Washington DC
            {"name": "CHI", "population": 2664000, "latitude": 41.8781, "longitude": -87.6298},  # Chicago
            {"name": "PA", "population": 2103000, "latitude": 39.9526, "longitude": -75.1652},   # Philadelphia
            {"name": "LON", "population": 8866000, "latitude": 51.5074, "longitude": -0.1278},   # London
            {"name": "MA", "population": 8866000, "latitude": 35.6762, "longitude": 139.6503}    # Tokyo (MA)
        ]
        
        self.virus = {
            "current_strain": "original",
            "strains": {
                "original": {
                    "parent": None,
                    "emergence_day": 0,
                    "infection_rate": 0.9,
                    "recovery_rate": 0.4,
                    "lethality": 0.015,  # 1.5% lethality
                    "attributes": {
                        "transmission_mode": "droplet",
                        "incubation_period": 5,
                        "symptom_severity": 6  # 1-10 scale
                    }
                }
            },
            "infection_rate": 0.9,
            "recovery_rate": 0.4,
            "lethality": 0.015,
            "mutation_rate": 0.002,  #chance of mutation per day per infected population
            "attributes": {
                "transmission_mode": "droplet",
                "incubation_period": 5,
                "symptom_severity": 6
            }
        }

books = SIR_Simulation_Parameters()

state_dictionary = books.state
city_array = books.cities
virus_config = books.virus

seed = "SF"
print("\nStarting pandemic simulation...")
state_dictionary, city_dictionary = start_pandemic(seed, state_dictionary, city_array, virus_config)

if "virus_history" not in city_dictionary:
    print("Initializing virus_history in city_dictionary...")
    city_dictionary["virus_history"] = {
        "day_0": {
            "current_strain": virus_config["current_strain"],
            "strains": copy.deepcopy(virus_config["strains"]),
            "mutation_rate": virus_config["mutation_rate"]
        }
    }

preloaded = {}

preloaded["day_0"] = copy.deepcopy(city_dictionary) 
pandemic_status = city_dictionary

active_strains = {"original"}
mutation_days = {}

for i in range(1, 50):
    pandemic_status = add_day(state_dictionary, pandemic_status, city_array)
    preloaded[f"day_{i}"] = copy.deepcopy(pandemic_status)
    
    current_day = i
    
    day_key = f"day_{i}"
    if "virus" in state_dictionary:
        if "virus_history" not in pandemic_status:
            pandemic_status["virus_history"] = {}
            
        pandemic_status["virus_history"][day_key] = {
            "current_strain": state_dictionary["virus"]["current_strain"],
            "strains": copy.deepcopy(state_dictionary["virus"]["strains"]),
            "mutation_rate": state_dictionary["virus"]["mutation_rate"]
        }
        
        current_strain = state_dictionary["virus"]["current_strain"]
        if current_strain not in active_strains:
            active_strains.add(current_strain)
            mutation_days[current_strain] = i
            
            strain_data = state_dictionary["virus"]["strains"][current_strain]
            parent = strain_data["parent"]
            if parent and parent in state_dictionary["virus"]["strains"]:
                parent_data = state_dictionary["virus"]["strains"][parent]
                inf_change = (strain_data["infection_rate"] / parent_data["infection_rate"] - 1) * 100
                leth_change = (strain_data["lethality"] / parent_data["lethality"] - 1) * 100
                
                print(f"\n=== NEW MUTATION on Day {i} ===")
                print(f"Strain: {current_strain} (evolved from {parent})")
                print(f"Infection rate: {strain_data['infection_rate']:.3f} ({inf_change:+.1f}%)")
                print(f"Lethality: {strain_data['lethality']:.4f} ({leth_change:+.1f}%)")
                
                if strain_data["attributes"]["transmission_mode"] != parent_data["attributes"]["transmission_mode"]:
                    print(f"Transmission changed: {parent_data['attributes']['transmission_mode']} → {strain_data['attributes']['transmission_mode']}")
    
    print(f"Simulated day {i}/50")

last_day = f"day_{49}"
if "virus_history" in preloaded[last_day]:
    print("\n=== VIRUS HISTORY WAS SUCCESSFULLY RECORDED ===")
    print(f"Number of days with virus data: {len(preloaded[last_day]['virus_history'])}")
    print(f"Number of strains that evolved: {len(active_strains) - 1}")  # -1 for original strain
else:
    print("\n=== ERROR: VIRUS HISTORY NOT FOUND IN SIMULATION DATA ===")
    if "virus" in state_dictionary:
        print("Virus data exists in state_dictionary")
        print(f"Current strain: {state_dictionary['virus']['current_strain']}")
        print(f"Number of strains: {len(state_dictionary['virus']['strains'])}")
    else:
        print("No virus data found in state_dictionary")

with open("pandemic_simulation.json", "w") as json_file:
    json.dump(preloaded, json_file, indent=4)