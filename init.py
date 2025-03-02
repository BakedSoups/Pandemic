import numpy as np
import json

with open("state.json", "r") as f:
    state_dictionary = json.load(f)

with open("init_cities.json", "r") as g:
    city_array = json.load(g)

with open("seed.json", "r") as h:
    seed = json.load(h)

def softmax(x):
    exp_x = np.exp(x - np.max(x))
    return exp_x / np.sum(exp_x)


travel_factor = 0.1

N = len(city_array)

sir_matrix = []

for i in range(N):
    res = 0
    if city_array[i]["name"] == seed:
        res = 1
    sir_matrix.append([city_array[i]["population"] - res, res, 0])




markov_matrix = travel_factor*np.random.rand(N, N) + 5*np.eye(N)
markov_matrix = np.apply_along_axis(softmax, axis = 0, arr = markov_matrix)


with open("state.json", "w") as g:
    state_dictionary["vector"] = sir_matrix
    state_dictionary["matrix"] = markov_matrix.tolist()
    json.dump(state_dictionary, g)


city_dictionary = {}

print(len(city_array))
for i in range(N):
    print(city_array[i]["name"])
    city_dictionary[city_array[i]["name"]] = {
        "sir_history" : [[float(sir_matrix[i][0])],[float(sir_matrix[i][1])], [float(sir_matrix[i][2])]],
        "latitude" : city_array[i]["latitude"],
        "longitude" : city_array[i]["longitude"]
    }

with open("cities.json", "w") as h:
    json.dump(city_dictionary, h)




# for i in range(N):
#     population = city_array[i]["population"]
#     arr = []
#     for j in range(N):
#         if i != j:
#             (travel_factor/population)
#     1-(N-1)*travel_factor




