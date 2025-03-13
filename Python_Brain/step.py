import numpy as np
from scipy.integrate import solve_ivp



dt = 5
a = 0.5   # Infection rate
b = 0.4   # Recovery rate

def sir_ode(t,y,a,b):
    S, I, R = tuple(y)
    N = S+I+R
    dSdt = (-a * S * I)/N
    dIdt = (a * S * I)/N - b * I
    dRdt = b * I
    return np.array([dSdt, dIdt, dRdt]) 




def hare_neimeyer(array):
    ints = np.floor(array).astype(int)
    remainder = array - ints
    deficit = int(round(sum(array))) - sum(ints)
    indices = np.argsort(remainder)[::-1]  # Sort by largest remainder
    for i in range(deficit):
        ints[indices[i]] += 1
    return ints

def clean_1(sir_matrix):
    return np.apply_along_axis(hare_neimeyer, axis = 0, arr = sir_matrix)


def clean_2(sir_matrix):  
    #print(sir_matrix)
    return np.apply_along_axis(hare_neimeyer, axis = 1, arr = sir_matrix)

def local_sir_evo(sir_array, a, b):
    t_span = (0,dt)
    t_eval = np.linspace(*t_span, 100)
    sol = solve_ivp(sir_ode, t_span, sir_array, args = (a,b), t_eval=t_eval, method='RK45')
    return np.array((sol.y[0][-1], sol.y[1][-1], sol.y[2][-1]))

def global_sir_evo(sir_matrix, a, b):
    return np.apply_along_axis(lambda matrix: local_sir_evo(matrix, a, b), axis = 1, arr = sir_matrix)


def track_movement(sir_matrix, markov_matrix, city_names):
    # Calculate the raw movement by applying the Markov matrix
    moved_matrix = markov_matrix @ sir_matrix
    
    # Track detailed movement information
    movement_data = []
    
    # each source city (row in sir_matrix)
    for i in range(len(sir_matrix)):
        from_city = city_names[i]
        s_source, i_source, r_source = sir_matrix[i]
        
        # each destination city (column in markov_matrix)
        for j in range(len(sir_matrix)):
            to_city = city_names[j]
            
            # Skip if source and destination are the same or probability is 0
            if i == j or markov_matrix[j][i] == 0:
                continue
                
            # probablility of people who traversed from city i to city j 
            transition_prob = markov_matrix[j][i]
            s_moved = s_source * transition_prob
            i_moved = i_source * transition_prob
            r_moved = r_source * transition_prob
            
            # if the sum is less than 0.1 nobody moved 
            if s_moved + i_moved + r_moved > 0.1:
                movement_data.append({
                    "from_city": from_city,
                    "to_city": to_city,
                    "s_count": int(s_moved),
                    "i_count": int(i_moved),
                    "r_count": int(r_moved),
                    "total": int(s_moved + i_moved + r_moved)
                })
    
    return moved_matrix, movement_data



# city_exodus is a dictionary where:
#   - keys are city names
#   - values are dictionaries containing destination cities and counts
def step_function(sir_matrix, markov_matrix, a, b, city_names=None):
    if city_names is None:
        return clean_2(global_sir_evo(clean_1(markov_matrix @ sir_matrix), a, b))
    else:
        # Track movement and return both the new state and movement data
        moved_matrix, movement_data = track_movement(sir_matrix, markov_matrix, city_names)
        new_sir_matrix = clean_2(global_sir_evo(clean_1(moved_matrix), a, b))
        
        # Create a city-centric view of who left and where they went
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

def rich_step_function():
    return
    
