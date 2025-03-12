import numpy as np 
import json
from step import step_function
import os

# Get the current working directory
directory = os.getcwd()



def softmax(x):
    exp_x = np.exp(x - np.max(x))
    return exp_x / np.sum(exp_x)

with open("state.json", "r") as f:
    state_dictionary = json.load(f)


sir_matrix = np.array(state_dictionary["vector"])
markov_matrix = np.array(state_dictionary["matrix"])
a = state_dictionary["infection_rate"]
b = state_dictionary["recovery_rate"]

#store this into a local dicionary instead (render 50)
sir_matrix = step_function(sir_matrix, markov_matrix, a , b)

print(sir_matrix)

with open("state.json", "w") as g:
    state_dictionary["vector"] = sir_matrix.tolist()
    json.dump(state_dictionary, g)


with open("init_cities.json", "r") as g:
    city_array = json.load(g)

with open("cities.json", "r") as g:
    city_dictionary = json.load(g)

N = len(city_array)

for i in range(N):
    city_dictionary[city_array[i]["name"]]["sir_history"][0].append(float(sir_matrix[i][0]))
    city_dictionary[city_array[i]["name"]]["sir_history"][1].append(float(sir_matrix[i][1]))
    city_dictionary[city_array[i]["name"]]["sir_history"][2].append(float(sir_matrix[i][2]))

with open("cities.json", "w") as g:
    json.dump(city_dictionary, g)

# for i in range(100):
#     print(sir_matrix)
#     print(np.sum(sir_matrix.flatten()))
#     sir_matrix = step_function(sir_matrix, markov_matrix)
