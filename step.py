import numpy as np
from scipy.integrate import solve_ivp
import matplotlib.pyplot as plt



dt = 5


a = 0.9   # Infection rate
b = 0.4   # Recovery rate

# SIR equations
def sir_ode(t, y):
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

def local_sir_evo(sir_array):
    t_span = (0,dt)
    t_eval = np.linspace(*t_span, 100)
    sol = solve_ivp(sir_ode, t_span, sir_array, t_eval=t_eval, method='RK45')
    return np.array((sol.y[0][-1], sol.y[1][-1], sol.y[2][-1]))

def global_sir_evo(sir_matrix):
    return np.apply_along_axis(local_sir_evo, axis = 1, arr = sir_matrix)



def step_function(sir_matrix, markov_matrix):
    return clean_2(global_sir_evo(clean_1(markov_matrix @ sir_matrix)))

def rich_step_function():
    return
    
