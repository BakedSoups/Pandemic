import json
# chat cooked this one ngl
def who_left_city(city_dictionary, city_name, day=None, days_range=None):
    """
    Get information about who left a specific city and where they went.
    
    Args:
        city_dictionary: The city dictionary containing movement data
        city_name: Name of the city to check
        day: Specific day to check (None to check the latest day)
        days_range: Tuple of (start_day, end_day) to get combined exodus over a period
        
    Returns:
        Dictionary with information about departures
    """
    if city_name not in city_dictionary:
        return {"error": f"City '{city_name}' not found"}
    
    if "exodus_history" not in city_dictionary[city_name]:
        return {"error": "No exodus data available for this city"}
    
    # Handle getting the latest day if day is None
    if day is None and days_range is None:
        day_keys = sorted(city_dictionary[city_name]["exodus_history"].keys(), 
                          key=lambda k: int(k.split('_')[1]))
        if not day_keys:
            return {"error": "No exodus data available"}
        day = int(day_keys[-1].split('_')[1])
        
    # Get data for a single day
    if day is not None:
        day_key = f"day_{day}"
        if day_key not in city_dictionary[city_name]["exodus_history"]:
            return {"error": f"No exodus data for day {day}"}
            
        exodus_data = city_dictionary[city_name]["exodus_history"][day_key]
        
        # If no one left the city
        if not exodus_data:
            return {
                "city": city_name,
                "day": day,
                "status": "No one left this city on this day"
            }
            
        # Calculate total people who left
        total_left = sum(dest_data["total"] for dest_data in exodus_data.values())
        
        return {
            "city": city_name,
            "day": day,
            "total_departures": total_left,
            "destinations": exodus_data
        }
    
    # Get combined data over a range of days
    elif days_range is not None:
        start_day, end_day = days_range
        combined_exodus = {}
        total_left = 0
        
        for d in range(start_day, end_day + 1):
            day_key = f"day_{d}"
            if day_key in city_dictionary[city_name]["exodus_history"]:
                daily_exodus = city_dictionary[city_name]["exodus_history"][day_key]
                
                for dest, counts in daily_exodus.items():
                    if dest not in combined_exodus:
                        combined_exodus[dest] = {
                            "total": 0,
                            "susceptible": 0,
                            "infected": 0,
                            "recovered": 0,
                            "days": []
                        }
                    
                    combined_exodus[dest]["total"] += counts["total"]
                    combined_exodus[dest]["susceptible"] += counts["susceptible"]
                    combined_exodus[dest]["infected"] += counts["infected"]
                    combined_exodus[dest]["recovered"] += counts["recovered"]
                    combined_exodus[dest]["days"].append(d)
                    
                    total_left += counts["total"]
        
        return {
            "city": city_name,
            "days": f"{start_day}-{end_day}",
            "total_departures": total_left,
            "destinations": combined_exodus
        }
        
    return {"error": "Invalid parameters"}


def print_exodus_report(exodus_data):
    """
    Pretty-print an exodus report from the who_left_city function
    
    Args:
        exodus_data: The dictionary returned by who_left_city()
        
    Returns:
        None, prints to console
    """
    if "error" in exodus_data:
        print(f"Error: {exodus_data['error']}")
        return
        
    if "status" in exodus_data:
        print(f"City: {exodus_data['city']}, Day: {exodus_data['day']}")
        print(exodus_data['status'])
        return
        
    print(f"=== EXODUS REPORT FOR {exodus_data['city']} ===")
    
    if "day" in exodus_data:
        print(f"Day: {exodus_data['day']}")
    else:
        print(f"Days: {exodus_data['days']}")
        
    print(f"Total people who left: {exodus_data['total_departures']}")
    print("\nDestination breakdown:")
    print("-" * 40)
    
    sorted_destinations = sorted(
        exodus_data['destinations'].items(),
        key=lambda x: x[1]['total'],
        reverse=True
    )
    
    for dest, data in sorted_destinations:
        print(f"→ {dest}: {data['total']} people")
        print(f"  • {data['susceptible']} susceptible")
        print(f"  • {data['infected']} infected")
        print(f"  • {data['recovered']} recovered")
        if "days" in data:
            print(f"  • Days: {data['days']}")
        print()


with open("pandemic_simulation.json", "r") as json_file:
    simulation_data = json.load(json_file)

# Check who left NYC on day 10
nyc_exodus = who_left_city(simulation_data["day_10"], "NYC", day=10)

# Print a nicely formatted report
print_exodus_report(nyc_exodus)

# nyc_week1 = who_left_city(simulation_data["day_7"], "NYC", days_range=(1, 7))
# print_exodus_report(nyc_week1)


# Get the NYC data for day 10
nyc_data = simulation_data["day_10"]["NYC"]

# Get the SIR values for day 10
# Remember that sir_history stores all days from 0 to current
susceptible = nyc_data["sir_history"][0][10]  # S value on day 10
infected = nyc_data["sir_history"][1][10]     # I value on day 10
recovered = nyc_data["sir_history"][2][10]    # R value on day 10

# Print the SIR data
print(f"NYC SIR data on day 10:")
print(f"Susceptible: {susceptible}")
print(f"Infected: {infected}")
print(f"Recovered: {recovered}")