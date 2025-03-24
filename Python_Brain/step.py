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
        "SF": {"NYC": 4, "WA": 5, "CHI": 3, "PA": 3, "LON": 9, "MA": 6},
        "NYC": {"SF": 4, "WA": 3, "CHI": 2, "PA": 1, "LON": 7, "MA": 8},
        "WA": {"SF": 5, "NYC": 3, "CHI": 3, "PA": 2, "LON": 8, "MA": 7},
        "CHI": {"SF": 3, "NYC": 2, "WA": 3, "PA": 1, "LON": 7, "MA": 6},
        "PA": {"SF": 3, "NYC": 1, "WA": 2, "CHI": 1, "LON": 6, "MA": 5},
        "LON": {"SF": 9, "NYC": 7, "WA": 8, "CHI": 7, "PA": 6, "MA": 10},
        "MA": {"SF": 6, "NYC": 8, "WA": 7, "CHI": 6, "PA": 5, "LON": 10}
    }

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

def check_for_mutations(virus, total_infected, day):
    """
    Check if virus mutations occur and update virus properties if they do
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

def step_function(sir_matrix, markov_matrix, a, b, city_names=None, current_day=0, in_transit=None, virus=None):
    """
    simplified step function that forces balanced travel between all cities
    """
    # handle basic case with no city names
    if city_names is None:
        return clean_2(global_sir_evo(clean_1(markov_matrix @ sir_matrix), a, b))
    
    # set up result structure
    sird_matrix = sir_matrix.copy()
    if sird_matrix.shape[1] == 3:  # SIR format
        death_column = np.zeros((sird_matrix.shape[0], 1))
        sird_matrix = np.hstack((sird_matrix, death_column))
    
    arrivals = {}
    city_exodus = {}
    updated_in_transit = []
    movement_data = []
    
    # initialize city exodus structure
    for city_name in city_names:
        city_exodus[city_name] = {"left_for": {}}
    
    # first process in-transit travelers
    if in_transit is not None:
        for traveler in in_transit:
            traveler["days_left"] -= 1
            
            if traveler["days_left"] <= 0:
                # travelers arrive at destination
                to_city = traveler["to_city"]
                from_city = traveler["from_city"]
                dest_idx = city_names.index(to_city)
                
                sird_matrix[dest_idx][0] += traveler["s_count"]
                sird_matrix[dest_idx][1] += traveler["i_count"]
                sird_matrix[dest_idx][2] += traveler["r_count"]
                if len(sird_matrix[dest_idx]) > 3:
                    sird_matrix[dest_idx][3] += traveler.get("d_count", 0)
                
                # record arrivals
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
                # process deaths in transit
                if traveler["i_count"] > 0 and virus is not None:
                    current_strain = virus["strains"][virus["current_strain"]]
                    lethality = current_strain["lethality"]
                    
                    deaths_in_transit = int(traveler["i_count"] * lethality * 0.1)  # 10% of normal rate
                    
                    if deaths_in_transit > 0:
                        traveler["i_count"] -= deaths_in_transit
                        if "d_count" not in traveler:
                            traveler["d_count"] = 0
                        traveler["d_count"] += deaths_in_transit
                        traveler["total"] -= deaths_in_transit
                
                updated_in_transit.append(traveler)
    
    # handle virus mutations
    if virus is not None:
        total_infected = sum(sird_matrix[:, 1])
        virus, mutation_occurred = check_for_mutations(virus, total_infected, current_day)
        
        current_strain = virus["strains"][virus["current_strain"]]
        a = current_strain["infection_rate"]
        b = current_strain["recovery_rate"]
        lethality = current_strain["lethality"]
    else:
        lethality = 0.01  # default lethality
    
    # process disease dynamics
    if sird_matrix.shape[1] == 3:
        sird_matrix = clean_2(global_sir_evo(clean_1(sird_matrix), a, b))
    else:
        sird_matrix = clean_2(global_sird_evo(clean_1(sird_matrix), a, b, lethality))
    
    # generate forced travel between ALL city pairs
    travel_durations = get_travel_durations()
    
    N = len(city_names)
    for i in range(N):
        from_city = city_names[i]
        
        # get population counts
        s_source, i_source, r_source, d_source = sird_matrix[i]
        total_alive = s_source + i_source + r_source  # exclude deaths
        
        if total_alive < 100:  # skip nearly empty cities
            continue
        
        # 2% of population will travel, distributed evenly among destinations
        leave_percent = 0.02
        total_leaving = int(total_alive * leave_percent)
        
        # calculate proportions of S/I/R
        s_ratio = s_source / max(1, total_alive)
        i_ratio = i_source / max(1, total_alive)
        r_ratio = r_source / max(1, total_alive)
        
        # destinations are all cities except current city
        destinations = [j for j in range(N) if j != i]
        travelers_per_dest = max(10, total_leaving // len(destinations))
        
        for j in destinations:
            to_city = city_names[j]
            
            # calculate travelers of each type
            s_moved = int(travelers_per_dest * s_ratio)
            i_moved = int(travelers_per_dest * i_ratio)
            r_moved = int(travelers_per_dest * r_ratio)
            total_moved = s_moved + i_moved + r_moved
            
            # skip if not enough people to move
            if total_moved < 1:
                continue
            
            # ensure we don't move more than available
            s_moved = min(s_moved, int(s_source))
            i_moved = min(i_moved, int(i_source))
            r_moved = min(r_moved, int(r_source))
            total_moved = s_moved + i_moved + r_moved
            
            # update sird matrix to reflect travelers leaving
            sird_matrix[i][0] -= s_moved
            sird_matrix[i][1] -= i_moved
            sird_matrix[i][2] -= r_moved
            
            # set up travel duration
            duration = 1
            if from_city in travel_durations and to_city in travel_durations[from_city]:
                duration = travel_durations[from_city][to_city]
            
            # add to exodus record
            if to_city not in city_exodus[from_city]["left_for"]:
                city_exodus[from_city]["left_for"][to_city] = {
                    "total": 0,
                    "susceptible": 0,
                    "infected": 0,
                    "recovered": 0,
                    "deaths": 0,
                    "duration": duration
                }
            
            city_exodus[from_city]["left_for"][to_city]["total"] += total_moved
            city_exodus[from_city]["left_for"][to_city]["susceptible"] += s_moved
            city_exodus[from_city]["left_for"][to_city]["infected"] += i_moved
            city_exodus[from_city]["left_for"][to_city]["recovered"] += r_moved
            
            # record movement
            movement_data.append({
                "from_city": from_city,
                "to_city": to_city,
                "s_count": s_moved,
                "i_count": i_moved,
                "r_count": r_moved,
                "total": total_moved
            })
            
            # handle travel time
            if duration > 1:
                # add to in-transit if duration > 1
                updated_in_transit.append({
                    "from_city": from_city,
                    "to_city": to_city,
                    "s_count": s_moved,
                    "i_count": i_moved,
                    "r_count": r_moved,
                    "total": total_moved,
                    "days_left": duration,
                    "duration": duration,
                    "departure_day": current_day
                })
            else:
                # add directly to destination city if duration = 1
                dest_idx = j
                sird_matrix[dest_idx][0] += s_moved
                sird_matrix[dest_idx][1] += i_moved
                sird_matrix[dest_idx][2] += r_moved
    
    # return the appropriate results
    if virus is not None:
        return sird_matrix, movement_data, city_exodus, updated_in_transit, arrivals, virus
    else:
        return sird_matrix, movement_data, city_exodus, updated_in_transit, arrivals

def rich_step_function():
    return