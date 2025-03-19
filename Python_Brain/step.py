import numpy as np
from scipy.integrate import solve_ivp
import concurrent.futures


dt = 5
a = 0.5   # Infection rate
b = 0.4   # Recovery rate

def sir_ode(t, y, a, b):
    S, I, R = tuple(y)
    N = S+I+R
    dSdt = (-a * S * I)/N
    dIdt = (a * S * I)/N - b * I
    dRdt = b * I
    return np.array([dSdt, dIdt, dRdt])

def sird_ode(t, y, a, b, lethality):
    """
    Extended ODE model that includes deaths:
    S: Susceptible
    I: Infected
    R: Recovered
    D: Deaths (new)
    
    Parameters:
    - a: infection rate
    - b: recovery rate
    - lethality: death rate (probability of death when infected)
    """
    S, I, R, D = tuple(y)
    N = S + I + R + D  # Total population including deaths
    
    dSdt = (-a * S * I) / N
    dIdt = (a * S * I) / N - (b * I) - (lethality * I)
    dRdt = b * I
    dDdt = lethality * I
    
    return np.array([dSdt, dIdt, dRdt, dDdt])

def get_travel_durations():
    """Define the travel durations between cities in days."""
    return {
        "SF": {"NYC": 5, "WA": 6, "CHI": 4, "PA": 3, "LON": 10, "MA": 2},
        "NYC": {"SF": 5, "WA": 3, "CHI": 2, "PA": 1, "LON": 7, "MA": 4},
        "WA": {"SF": 6, "NYC": 3, "CHI": 3, "PA": 2, "LON": 9, "MA": 5},
        "CHI": {"SF": 4, "NYC": 2, "WA": 3, "PA": 1, "LON": 8, "MA": 3},
        "PA": {"SF": 3, "NYC": 1, "WA": 2, "CHI": 1, "LON": 6, "MA": 2},
        "LON": {"SF": 10, "NYC": 7, "WA": 9, "CHI": 8, "PA": 6, "MA": 12},
        "MA": {"SF": 2, "NYC": 4, "WA": 5, "CHI": 3, "PA": 2, "LON": 12}
    }

def process_city_pair(args):
    i, j, sir_matrix, markov_matrix, city_names = args
    
    from_city = city_names[i]
    to_city = city_names[j]
    
    if i == j or markov_matrix[j][i] == 0:
        return None
    
    s_source, i_source, r_source = sir_matrix[i][:3]  # Get first 3 elements for SIR
    
    transition_prob = markov_matrix[j][i]
    s_moved = s_source * transition_prob
    i_moved = i_source * transition_prob
    r_moved = r_source * transition_prob
    
    if s_moved + i_moved + r_moved > 0.1:
        return {
            "from_city": from_city,
            "to_city": to_city,
            "s_count": int(s_moved),
            "i_count": int(i_moved),
            "r_count": int(r_moved),
            "total": int(s_moved + i_moved + r_moved)
        }
    return None

def hare_neimeyer(array):
    ints = np.floor(array).astype(int)
    remainder = array - ints
    deficit = int(round(sum(array))) - sum(ints)
    indices = np.argsort(remainder)[::-1]  # Sort by largest remainder
    for i in range(deficit):
        ints[indices[i]] += 1
    return ints

def clean_1(sir_matrix):
    return np.apply_along_axis(hare_neimeyer, axis=0, arr=sir_matrix)

def clean_2(sir_matrix):  
    return np.apply_along_axis(hare_neimeyer, axis=1, arr=sir_matrix)

def local_sir_evo(sir_array, a, b):
    t_span = (0,dt)
    t_eval = np.linspace(*t_span, 100)
    sol = solve_ivp(sir_ode, t_span, sir_array, args=(a,b), t_eval=t_eval, method='RK45')
    return np.array((sol.y[0][-1], sol.y[1][-1], sol.y[2][-1]))

def local_sird_evo(sird_array, a, b, lethality):
    """Evolve the SIRD model for a single city"""
    t_span = (0, dt)
    t_eval = np.linspace(*t_span, 100)
    sol = solve_ivp(sird_ode, t_span, sird_array, args=(a, b, lethality), 
                   t_eval=t_eval, method='RK45')
    return np.array((sol.y[0][-1], sol.y[1][-1], sol.y[2][-1], sol.y[3][-1]))

def global_sir_evo(sir_matrix, a, b):
    return np.apply_along_axis(lambda matrix: local_sir_evo(matrix, a, b), axis=1, arr=sir_matrix)

def global_sird_evo(sird_matrix, a, b, lethality):
    """Evolve the SIRD model for all cities"""
    return np.apply_along_axis(
        lambda matrix: local_sird_evo(matrix, a, b, lethality), 
        axis=1, 
        arr=sird_matrix
    )

def track_movement(sir_matrix, markov_matrix, city_names, max_workers=None):
    moved_matrix = markov_matrix @ sir_matrix
    
    args_list = [(i, j, sir_matrix, markov_matrix, city_names) 
                 for i in range(len(sir_matrix)) 
                 for j in range(len(sir_matrix))]
    
    movement_data = []
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        results = executor.map(process_city_pair, args_list)
        
        for result in results:
            if result is not None:
                movement_data.append(result)
    
    return moved_matrix, movement_data

def check_for_mutations(virus, total_infected, day):
    """
    Check if virus mutations occur and update virus properties if they do
    
    Parameters:
    - virus: current virus properties
    - total_infected: current total infected population
    - day: current simulation day
    
    Returns:
    - updated virus dictionary
    - Boolean indicating if mutation occurred
    """
    mutation_chance = virus["mutation_rate"] * (total_infected / 10000)
    
    mutation_chance = min(0.05, mutation_chance)
    
    if np.random.random() < mutation_chance:
        new_strain_id = len(virus["strains"]) + 1
        strain_name = f"strain_{new_strain_id}"
        
        infection_modifier = np.random.normal(1.0, 0.2)  # 20% variation
        lethality_modifier = np.random.normal(1.0, 0.15)  # 15% variation
        
        new_strain = {
            "parent": virus["current_strain"],
            "emergence_day": day,
            "infection_rate": max(0.1, min(2.0, virus["infection_rate"] * infection_modifier)),
            "recovery_rate": virus["recovery_rate"],
            "lethality": max(0.001, min(0.3, virus["lethality"] * lethality_modifier)),
            "attributes": virus["attributes"].copy()
        }
        
        if np.random.random() < 0.25:
            attr_to_change = np.random.choice(list(virus["attributes"].keys()))
            
            if attr_to_change == "transmission_mode":
                modes = ["droplet", "airborne", "contact", "fomite"]
                modes.remove(virus["attributes"]["transmission_mode"])
                new_strain["attributes"]["transmission_mode"] = np.random.choice(modes)
            elif attr_to_change == "incubation_period":
                new_period = virus["attributes"]["incubation_period"] + np.random.randint(-2, 3)
                new_strain["attributes"]["incubation_period"] = max(1, new_period)
            elif attr_to_change == "symptom_severity":
                severity = virus["attributes"]["symptom_severity"] + np.random.randint(-2, 3)
                new_strain["attributes"]["symptom_severity"] = max(1, min(10, severity))
        
        virus["strains"][strain_name] = new_strain
        virus["current_strain"] = strain_name
        
        print(f"Day {day}: New virus mutation ({strain_name}) emerged!")
        print(f"  - Infection rate: {new_strain['infection_rate']:.3f} " + 
              f"({(new_strain['infection_rate']/virus['infection_rate']-1)*100:.1f}% change)")
        print(f"  - Lethality: {new_strain['lethality']:.4f} " +
              f"({(new_strain['lethality']/virus['lethality']-1)*100:.1f}% change)")
        if new_strain["attributes"]["transmission_mode"] != virus["attributes"]["transmission_mode"]:
            print(f"  - New transmission mode: {new_strain['attributes']['transmission_mode']}")
        
        return virus, True
    
    return virus, False

def original_step_function(sir_matrix, markov_matrix, a, b, city_names=None):
    if city_names is None:
        return clean_2(global_sir_evo(clean_1(markov_matrix @ sir_matrix), a, b))
    else:
        moved_matrix, movement_data = track_movement(sir_matrix, markov_matrix, city_names)
        new_sir_matrix = clean_2(global_sir_evo(clean_1(moved_matrix), a, b))
        
        city_exodus = {}
        for city_name in city_names:
            city_exodus[city_name] = {"left_for": {}}
            
        for move in movement_data:
            from_city = move["from_city"]
            to_city = move["to_city"]
            
            if to_city not in city_exodus[from_city]["left_for"]:
                city_exodus[from_city]["left_for"][to_city] = {
                    "total": 0,
                    "susceptible": 0,
                    "infected": 0,
                    "recovered": 0
                }
                
            city_exodus[from_city]["left_for"][to_city]["total"] += move["total"]
            city_exodus[from_city]["left_for"][to_city]["susceptible"] += move["s_count"]
            city_exodus[from_city]["left_for"][to_city]["infected"] += move["i_count"]
            city_exodus[from_city]["left_for"][to_city]["recovered"] += move["r_count"]
        
        return new_sir_matrix, movement_data, city_exodus

def step_function(sir_matrix, markov_matrix, a, b, city_names=None, current_day=0, in_transit=None, virus=None):
    """
    Enhanced step function that supports:
    - SIRD model (deaths)
    - Virus mutations
    - Virus attributes affecting transmission
    """
    if virus is None:
        virus = {
            "current_strain": "original",
            "strains": {
                "original": {
                    "parent": None,
                    "emergence_day": 0,
                    "infection_rate": a,
                    "recovery_rate": b,
                    "lethality": 0.01,  # 1% base lethality
                    "attributes": {
                        "transmission_mode": "droplet",
                        "incubation_period": 5,
                        "symptom_severity": 5
                    }
                }
            },
            "infection_rate": a,
            "recovery_rate": b,
            "lethality": 0.01,
            "mutation_rate": 0.002,
            "attributes": {
                "transmission_mode": "droplet",
                "incubation_period": 5,
                "symptom_severity": 5
            }
        }
    
    if city_names is None:
        return clean_2(global_sir_evo(clean_1(markov_matrix @ sir_matrix), a, b))
    
    if sir_matrix.shape[1] == 3:  # If using standard SIR [S,I,R]
        death_column = np.zeros((sir_matrix.shape[0], 1))
        sird_matrix = np.hstack((sir_matrix, death_column))
    else:
        sird_matrix = sir_matrix.copy()
    
    arrivals = {}
    still_in_transit = []
    
    if in_transit is not None:
        for traveler in in_transit:
            traveler["days_left"] -= 1
            
            if traveler["days_left"] <= 0:
                to_city = traveler["to_city"]
                from_city = traveler["from_city"]
                dest_idx = city_names.index(to_city)
                
                sird_matrix[dest_idx][0] += traveler["s_count"]
                sird_matrix[dest_idx][1] += traveler["i_count"]
                sird_matrix[dest_idx][2] += traveler["r_count"]
                if len(sird_matrix[dest_idx]) > 3:
                    sird_matrix[dest_idx][3] += traveler.get("d_count", 0)
                
                if to_city not in arrivals:
                    arrivals[to_city] = {}
                
                if from_city not in arrivals[to_city]:
                    arrivals[to_city][from_city] = {
                        "total": 0,
                        "susceptible": 0,
                        "infected": 0,
                        "recovered": 0,
                        "deaths": traveler.get("d_count", 0),
                        "departure_day": traveler["departure_day"]
                    }
                
                arrivals[to_city][from_city]["total"] += traveler["total"]
                arrivals[to_city][from_city]["susceptible"] += traveler["s_count"]
                arrivals[to_city][from_city]["infected"] += traveler["i_count"]
                arrivals[to_city][from_city]["recovered"] += traveler["r_count"]
            else:
                if traveler["i_count"] > 0 and len(sird_matrix[0]) > 3:
                    current_strain = virus["strains"][virus["current_strain"]]
                    lethality = current_strain["lethality"]
                    
                    deaths_in_transit = int(traveler["i_count"] * lethality * 0.1)  # 10% of normal rate
                    
                    if deaths_in_transit > 0:
                        traveler["i_count"] -= deaths_in_transit
                        if "d_count" not in traveler:
                            traveler["d_count"] = 0
                        traveler["d_count"] += deaths_in_transit
                        traveler["total"] -= deaths_in_transit
                
                still_in_transit.append(traveler)
    
    moved_matrix, movement_data = track_movement(sird_matrix, markov_matrix, city_names)
    
    city_exodus = {}
    new_travelers = []
    
    for city_name in city_names:
        city_exodus[city_name] = {"left_for": {}}
    
    travel_durations = get_travel_durations()
    
    total_infected = sum(sird_matrix[:, 1])
    virus, mutation_occurred = check_for_mutations(virus, total_infected, current_day)
    
    current_strain = virus["strains"][virus["current_strain"]]
    a = current_strain["infection_rate"]
    b = current_strain["recovery_rate"]
    lethality = current_strain["lethality"]
    virus["infection_rate"] = a
    virus["recovery_rate"] = b
    virus["lethality"] = lethality
    virus["attributes"] = current_strain["attributes"]
    
    transmission_mode = virus["attributes"]["transmission_mode"]
    
    for move in movement_data:
        from_city = move["from_city"]
        to_city = move["to_city"]
        
        duration = 1
        if from_city in travel_durations and to_city in travel_durations[from_city]:
            duration = travel_durations[from_city][to_city]
        
        if to_city not in city_exodus[from_city]["left_for"]:
            city_exodus[from_city]["left_for"][to_city] = {
                "total": 0,
                "susceptible": 0,
                "infected": 0,
                "recovered": 0,
                "deaths": 0,
                "duration": duration
            }
        
        city_exodus[from_city]["left_for"][to_city]["total"] += move["total"]
        city_exodus[from_city]["left_for"][to_city]["susceptible"] += move["s_count"]
        city_exodus[from_city]["left_for"][to_city]["infected"] += move["i_count"]
        city_exodus[from_city]["left_for"][to_city]["recovered"] += move["r_count"]
        
        if duration > 1:
            new_travelers.append({
                "from_city": from_city,
                "to_city": to_city,
                "s_count": move["s_count"],
                "i_count": move["i_count"],
                "r_count": move["r_count"],
                "total": move["total"],
                "days_left": duration,
                "duration": duration,
                "departure_day": current_day
            })
            
            from_idx = city_names.index(from_city)
            sird_matrix[from_idx][0] -= move["s_count"]
            sird_matrix[from_idx][1] -= move["i_count"]
            sird_matrix[from_idx][2] -= move["r_count"]
        
    new_sird_matrix = clean_2(global_sird_evo(clean_1(moved_matrix), a, b, lethality))
    
    updated_in_transit = still_in_transit + new_travelers
    
    return new_sird_matrix, movement_data, city_exodus, updated_in_transit, arrivals, virus

def rich_step_function():
    return