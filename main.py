import numpy as np 
from step import step_function

def softmax(x):
    exp_x = np.exp(x - np.max(x))
    return exp_x / np.sum(exp_x)

sir_matrix = np.array([[10000,0,3],[10000,0,6],[60000,1,8],[1000,0,0],[100,0,0]])

markov_matrix = np.random.rand(5, 5) + np.eye(5)

markov_matrix = np.apply_along_axis(softmax, axis = 0, arr = markov_matrix)
print(markov_matrix)

for i in range(100):
    print(sir_matrix)
    print(np.sum(sir_matrix.flatten()))
    sir_matrix = step_function(sir_matrix, markov_matrix)