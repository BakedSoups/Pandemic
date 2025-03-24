import json

def who_left_city(city_dictionary, city_name, day=None, days_range=None, include_transit=True):
    """
    Get information about who left a specific city and where they went.
    
    Args:
        city_dictionary: The city dictionary containing movement data
        city_name: Name of the city to check
        day: Specific day to check (None to check the latest day)
        days_range: Tuple of (start_day, end_day) to get combined exodus over a period
        include_transit: Whether to include people still in transit
        
    Returns:
        Dictionary with information about departures
    """
    if city_name not in city_dictionary:
        return {"error": f"City '{city_name}' not found"}
    
    if "exodus_history" not in city_dictionary[city_name]:
        return {"error": "No exodus data available for this city"}
    
    if day is None and days_range is None:
        day_keys = sorted(city_dictionary[city_name]["exodus_history"].keys(), 
                          key=lambda k: int(k.split('_')[1]))
        if not day_keys:
            return {"error": "No exodus data available"}
        day = int(day_keys[-1].split('_')[1])
    
    result = {}
    
    if day is not None:
        day_key = f"day_{day}"
        if day_key not in city_dictionary[city_name]["exodus_history"]:
            return {"error": f"No exodus data for day {day}"}
            
        exodus_data = city_dictionary[city_name]["exodus_history"][day_key]
        
        if not exodus_data:
            result = {
                "city": city_name,
                "day": day,
                "status": "No one left this city on this day"
            }
        else:
            total_left = sum(dest_data["total"] for dest_data in exodus_data.values())
            
            result = {
                "city": city_name,
                "day": day,
                "total_departures": total_left,
                "destinations": exodus_data
            }
            
            if "virus_history" in city_dictionary and day_key in city_dictionary["virus_history"]:
                virus_data = city_dictionary["virus_history"][day_key]
                result["virus"] = {
                    "current_strain": virus_data["current_strain"],
                    "properties": virus_data["strains"][virus_data["current_strain"]]
                }
            elif day_key in city_dictionary.get("virus_history", {}):
                virus_data = city_dictionary["virus_history"][day_key]
                result["virus"] = {
                    "current_strain": virus_data["current_strain"],
                    "properties": virus_data["strains"][virus_data["current_strain"]]
                }
    
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
                            "deaths": 0,
                            "days": [],
                            "duration": counts.get("duration", 1)
                        }
                    
                    combined_exodus[dest]["total"] += counts["total"]
                    combined_exodus[dest]["susceptible"] += counts["susceptible"]
                    combined_exodus[dest]["infected"] += counts["infected"]
                    combined_exodus[dest]["recovered"] += counts["recovered"]
                    if "deaths" in counts:
                        combined_exodus[dest]["deaths"] += counts["deaths"]
                    combined_exodus[dest]["days"].append(d)
                    
                    total_left += counts["total"]
        
        result = {
            "city": city_name,
            "days": f"{start_day}-{end_day}",
            "total_departures": total_left,
            "destinations": combined_exodus
        }
        
        latest_day = f"day_{end_day}"
        if "virus_history" in city_dictionary and latest_day in city_dictionary["virus_history"]:
            virus_data = city_dictionary["virus_history"][latest_day]
            result["virus"] = {
                "current_strain": virus_data["current_strain"],
                "properties": virus_data["strains"][virus_data["current_strain"]]
            }
        elif latest_day in city_dictionary.get("virus_history", {}):
            virus_data = city_dictionary["virus_history"][latest_day]
            result["virus"] = {
                "current_strain": virus_data["current_strain"],
                "properties": virus_data["strains"][virus_data["current_strain"]]
            }
    
    if include_transit and "in_transit" in city_dictionary and result:
        city_travelers = [t for t in city_dictionary["in_transit"] 
                         if t["from_city"] == city_name]
        
        if city_travelers:
            in_transit_data = {}
            
            for traveler in city_travelers:
                dest = traveler["to_city"]
                if dest not in in_transit_data:
                    in_transit_data[dest] = {
                        "total": 0,
                        "susceptible": 0,
                        "infected": 0,
                        "recovered": 0,
                        "deaths": 0,
                        "days_left": traveler["days_left"],
                        "duration": traveler["duration"],
                        "departure_day": traveler["departure_day"]
                    }
                
                in_transit_data[dest]["total"] += traveler["total"]
                in_transit_data[dest]["susceptible"] += traveler["s_count"]
                in_transit_data[dest]["infected"] += traveler["i_count"]
                in_transit_data[dest]["recovered"] += traveler["r_count"]
                if "d_count" in traveler:
                    in_transit_data[dest]["deaths"] += traveler["d_count"]
            
            result["in_transit"] = in_transit_data
    
    return result or {"error": "Invalid parameters"}

def print_exodus_report(exodus_data):
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
    
    if "virus" in exodus_data:
        virus = exodus_data["virus"]
        props = virus["properties"]
        
        print(f"\nActive virus: {virus['current_strain']}")
        print(f"  • Transmission mode: {props['attributes']['transmission_mode']}")
        print(f"  • Infection rate: {props['infection_rate']:.3f}")
        print(f"  • Recovery rate: {props['recovery_rate']:.3f}")
        print(f"  • Lethality: {props['lethality']:.4f} ({props['lethality']*100:.2f}%)")
        print(f"  • Incubation period: {props['attributes']['incubation_period']} days")
        print(f"  • Symptom severity: {props['attributes']['symptom_severity']}/10")
    else:
        print("\nNo virus data available for this report")
    
    print("\nDestination breakdown:")
    print("-" * 40)
    
    sorted_destinations = sorted(
        exodus_data['destinations'].items(),
        key=lambda x: x[1]['total'],
        reverse=True
    )
    
    for dest, data in sorted_destinations:
        duration_text = ""
        if "duration" in data:
            duration_text = f" ({data['duration']} days)"
            
        print(f"→ {dest}{duration_text}: {data['total']} people")
        print(f"  • {data['susceptible']} susceptible")
        print(f"  • {data['infected']} infected")
        print(f"  • {data['recovered']} recovered")
        
        if "deaths" in data and data["deaths"] > 0:
            print(f"  • {data['deaths']} deaths")
            
        if "days" in data:
            print(f"  • Days: {sorted(data['days'])}")
        print()
    
    if "in_transit" in exodus_data and exodus_data["in_transit"]:
        print("\nCurrently in transit:")
        print("-" * 40)
        
        sorted_transit = sorted(
            exodus_data["in_transit"].items(),
            key=lambda x: (x[1]["days_left"], -x[1]["total"])
        )
        
        for dest, data in sorted_transit:
            print(f"→ {dest} ({data['days_left']} days left of {data['duration']} day journey): {data['total']} people")
            print(f"  • Departed on day: {data['departure_day']}")
            print(f"  • {data['susceptible']} susceptible")
            print(f"  • {data['infected']} infected")
            print(f"  • {data['recovered']} recovered")
            
            if "deaths" in data and data["deaths"] > 0:
                print(f"  • {data['deaths']} deaths")
                
            print()

def get_city_stats(city_dictionary, city_name, day=None):
    """
    Get comprehensive statistics for a city including deaths and virus info
    
    Args:
        city_dictionary: The city dictionary containing health data
        city_name: Name of the city to check
        day: Specific day to check (None to check the latest day)
        
    Returns:
        Dictionary with detailed city statistics
    """
    if city_name not in city_dictionary:
        return {"error": f"City '{city_name}' not found"}
    
    history = city_dictionary[city_name]["sir_history"]
    
    has_deaths = len(history) > 3
    
    if day is None:
        day = len(history[0]) - 1
    
    day_key = f"day_{day}"
    
    stats = {
        "susceptible": history[0][day],
        "infected": history[1][day],
        "recovered": history[2][day]
    }
    
    if has_deaths:
        stats["deaths"] = history[3][day]
    else:
        stats["deaths"] = 0
    
    stats["total_population"] = stats["susceptible"] + stats["infected"] + stats["recovered"] + stats["deaths"]
    stats["percent_infected"] = (stats["infected"] / stats["total_population"]) * 100
    stats["percent_recovered"] = (stats["recovered"] / stats["total_population"]) * 100
    
    if has_deaths:
        stats["percent_deaths"] = (stats["deaths"] / stats["total_population"]) * 100
        stats["case_fatality_rate"] = (stats["deaths"] / (stats["recovered"] + stats["deaths"])) * 100 if (stats["recovered"] + stats["deaths"]) > 0 else 0
    
    virus_data = None
    if "virus_history" in city_dictionary and day_key in city_dictionary["virus_history"]:
        virus_data = city_dictionary["virus_history"][day_key]
    elif day_key in city_dictionary.get("virus_history", {}):
        virus_data = city_dictionary["virus_history"][day_key]
        
    if virus_data:
        current_strain = virus_data["current_strain"]
        strain_data = virus_data["strains"][current_strain]
        
        stats["virus"] = {
            "current_strain": current_strain,
            "strain_data": strain_data,
            "mutation_rate": virus_data["mutation_rate"]
        }
    
    return {
        "city": city_name,
        "day": day,
        "stats": stats
    }

def print_city_stats(stats_data):
    if "error" in stats_data:
        print(f"Error: {stats_data['error']}")
        return
        
    city = stats_data["city"]
    day = stats_data["day"]
    stats = stats_data["stats"]
    
    print(f"=== HEALTH STATISTICS FOR {city} (Day {day}) ===")
    
    print(f"Total population: {int(stats['total_population'])}")
    print(f"  • Susceptible: {int(stats['susceptible'])} ({stats['susceptible']/stats['total_population']*100:.2f}%)")
    print(f"  • Infected: {int(stats['infected'])} ({stats['percent_infected']:.2f}%)")
    print(f"  • Recovered: {int(stats['recovered'])} ({stats['percent_recovered']:.2f}%)")
    
    if "percent_deaths" in stats:
        print(f"  • Deaths: {int(stats['deaths'])} ({stats['percent_deaths']:.2f}%)")
        print(f"  • Case fatality rate: {stats['case_fatality_rate']:.2f}%")
    
    if "virus" in stats:
        virus = stats["virus"]
        strain = virus["strain_data"]
        
        print(f"\nVirus information:")
        print(f"  • Current strain: {virus['current_strain']}")
        print(f"  • Transmission mode: {strain['attributes']['transmission_mode']}")
        print(f"  • Infection rate: {strain['infection_rate']:.3f}")
        print(f"  • Recovery rate: {strain['recovery_rate']:.3f}")
        print(f"  • Lethality: {strain['lethality']:.4f} ({strain['lethality']*100:.2f}%)")
        print(f"  • Mutation rate: {virus['mutation_rate']:.4f}")
        
        if virus["current_strain"] != "original" and "emergence_day" in strain:
            print(f"  • Emerged on day: {strain['emergence_day']}")
            print(f"  • Parent strain: {strain['parent']}")
    else:
        print("\nNo virus data available")
    
    print()

def get_mutation_history(city_dictionary):
    """
    Get the complete history of virus mutations throughout the simulation
    
    Args:
        city_dictionary: The city dictionary containing virus history
        
    Returns:
        Dictionary with mutation history
    """
    virus_history = None
    if "virus_history" in city_dictionary:
        virus_history = city_dictionary["virus_history"]
    
    if not virus_history:
        return {"error": "No virus history available"}
    
    strains = {}
    timeline = []
    
    for day_key, virus_data in virus_history.items():
        day = int(day_key.split('_')[1])
        
        for strain_id, strain_data in virus_data["strains"].items():
            if strain_id not in strains:
                strains[strain_id] = {
                    "emergence_day": strain_data.get("emergence_day", 0),
                    "parent": strain_data.get("parent", None),
                    "infection_rate": strain_data["infection_rate"],
                    "recovery_rate": strain_data["recovery_rate"],
                    "lethality": strain_data["lethality"],
                    "attributes": strain_data["attributes"]
                }
                
                timeline.append({
                    "day": strain_data.get("emergence_day", 0),
                    "strain": strain_id,
                    "parent": strain_data.get("parent", None)
                })
    
    timeline.sort(key=lambda x: x["day"])
    
    return {
        "total_strains": len(strains),
        "strains": strains,
        "timeline": timeline
    }

def print_mutation_history(mutation_data):
    if "error" in mutation_data:
        print(f"Error: {mutation_data['error']}")
        return
        
    print("=== VIRUS MUTATION HISTORY ===")
    print(f"Total strains: {mutation_data['total_strains']}")
    
    print("\nMutation timeline:")
    print("-" * 40)
    
    for item in mutation_data["timeline"]:
        strain = item["strain"]
        day = item["day"]
        parent = item["parent"]
        
        strain_data = mutation_data["strains"][strain]
        
        if parent:
            parent_data = mutation_data["strains"][parent]
            inf_change = (strain_data["infection_rate"] / parent_data["infection_rate"] - 1) * 100
            leth_change = (strain_data["lethality"] / parent_data["lethality"] - 1) * 100
            
            print(f"Day {day}: {strain} emerged (from {parent})")
            print(f"  • Infection rate: {strain_data['infection_rate']:.3f} ({inf_change:+.1f}%)")
            print(f"  • Lethality: {strain_data['lethality']:.4f} ({leth_change:+.1f}%)")
        else:
            print(f"Day {day}: {strain} (original strain)")
            print(f"  • Infection rate: {strain_data['infection_rate']:.3f}")
            print(f"  • Lethality: {strain_data['lethality']:.4f}")
        
        if parent and strain_data["attributes"]["transmission_mode"] != parent_data["attributes"]["transmission_mode"]:
            print(f"  • Transmission changed: {parent_data['attributes']['transmission_mode']} → {strain_data['attributes']['transmission_mode']}")
        else:
            print(f"  • Transmission mode: {strain_data['attributes']['transmission_mode']}")
        
        print()

if __name__ == "__main__":
    with open("pandemic_simulation.json", "r") as json_file:
        simulation_data = json.load(json_file)

    print("Checking for virus history in simulation data...")
    found_history = False
    
    last_day_key = max(simulation_data.keys(), key=lambda k: int(k.split('_')[1]))
    last_day_data = simulation_data[last_day_key]
    
    if "virus_history" in last_day_data:
        print(f"Found virus history at global level with {len(last_day_data['virus_history'])} entries")
        found_history = True
    
    if not found_history:
        print("No virus history found in the simulation data")
    
    nyc_stats = get_city_stats(simulation_data[last_day_key], "NYC")
    print_city_stats(nyc_stats)
    
    nyc_exodus = who_left_city(simulation_data["day_2"], "NYC", day=2)
    print_exodus_report(nyc_exodus)
    
    mutations = get_mutation_history(simulation_data[last_day_key])
    print_mutation_history(mutations)