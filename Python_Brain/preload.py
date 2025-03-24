from simulation import *
import pprint
import copy
import json

# goal is to create a prerendered json of all the days incrementally

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
            {"name": "SF", "population": 808988, "latitude": 37.795, "longitude": -122.419},
            {"name": "NYC", "population": 8258000, "latitude": 40.71, "longitude": -74.006},
            {"name": "WA", "population": 455924, "latitude": 25.7617, "longitude": -80.1918},
            {"name": "CHI", "population": 2664000, "latitude": 41.8781, "longitude": -87.6298},
            {"name": "PA", "population": 2103000, "latitude": 41.8781, "longitude": -87.6298},
            {"name": "LON", "population": 8866000, "latitude": 41.8781, "longitude": -87.6298},
            {"name": "MA", "population": 8866000, "latitude": 41.8781, "longitude": -87.6298}
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
            "mutation_rate": 0.002,  # Chance of mutation per day per infected population
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

# print("\n=== INITIAL VIRUS CONFIGURATION ===")
# print(f"Infection rate: {virus_config['infection_rate']}")
# print(f"Recovery rate: {virus_config['recovery_rate']}")
# print(f"Lethality: {virus_config['lethality']}")
# print(f"Mutation rate: {virus_config['mutation_rate']}")
# print(f"Transmission mode: {virus_config['attributes']['transmission_mode']}")
# print(f"Incubation period: {virus_config['attributes']['incubation_period']} days")
# print(f"Symptom severity: {virus_config['attributes']['symptom_severity']}/10")

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

# print("\nSimulation complete! Data saved to pandemic_simulation.json")

# total_infected = 0
# total_deaths = 0
# total_population = 0

# for city_name in [city["name"] for city in city_array]:
#     city_data = preloaded[last_day][city_name]
#     current_infected = city_data["sir_history"][1][-1]
    
#     if len(city_data["sir_history"]) > 3:
#         current_deaths = city_data["sir_history"][3][-1]
#         total_deaths += current_deaths
    
#     total_infected += current_infected
#     total_population += sum(city_data["sir_history"][j][-1] for j in range(len(city_data["sir_history"])))

# print(f"\nFinal statistics (Day 49):")
# print(f"Total infected: {int(total_infected)} ({total_infected/total_population*100:.2f}%)")

# if total_deaths > 0:
#     print(f"Total deaths: {int(total_deaths)} ({total_deaths/total_population*100:.2f}%)")

# if active_strains and len(active_strains) > 1:
#     print("\n=== VIRUS MUTATION SUMMARY ===")
#     current_strain = state_dictionary["virus"]["current_strain"]
#     print(f"Final active strain: {current_strain}")
    
#     for strain in sorted(active_strains, key=lambda s: 0 if s == "original" else mutation_days.get(s, 999)):
#         if strain == "original":
#             strain_data = state_dictionary["virus"]["strains"]["original"]
#             print(f"Day 0: original strain")
#             print(f"  • Infection rate: {strain_data['infection_rate']:.3f}")
#             print(f"  • Lethality: {strain_data['lethality']:.4f}")
#             print(f"  • Transmission: {strain_data['attributes']['transmission_mode']}")
#         else:
#             day = mutation_days.get(strain, "unknown")
#             strain_data = state_dictionary["virus"]["strains"][strain]
#             print(f"Day {day}: {strain}")
#             print(f"  • Infection rate: {strain_data['infection_rate']:.3f}")
#             print(f"  • Lethality: {strain_data['lethality']:.4f}")
#             print(f"  • Transmission: {strain_data['attributes']['transmission_mode']}")
# else:
#     print("\nNo virus mutations occurred during the simulation.")