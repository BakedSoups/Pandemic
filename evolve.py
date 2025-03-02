import numpy as np 
import json
from step import step_function

def softmax(x):
    exp_x = np.exp(x - np.max(x))
    return exp_x / np.sum(exp_x)

with open("state.json", "r") as f:
    state_dictionary = json.load(f)


# markov_matrix = np.random.rand(5, 5) + 2*np.eye(5)
# markov_matrix = np.apply_along_axis(softmax, axis = 0, arr = markov_matrix)
# state_dictionary["matrix"] = markov_matrix.tolist()

sir_matrix = np.array(state_dictionary["vector"])
markov_matrix = np.array(state_dictionary["matrix"])
a = state_dictionary["infection_rate"]
b = state_dictionary["recovery_rate"]







sir_matrix = step_function(sir_matrix, markov_matrix, a , b)
print(sir_matrix)

with open("state.json", "w") as g:
    state_dictionary["vector"] = sir_matrix.tolist()
    json.dump(state_dictionary, g)


# for i in range(100):
#     print(sir_matrix)
#     print(np.sum(sir_matrix.flatten()))
#     sir_matrix = step_function(sir_matrix, markov_matrix)