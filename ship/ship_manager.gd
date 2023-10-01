extends Node

var ships : Dictionary = {}
var landing_points : Array = []

## Signal emitted when a ship is correctly cleared for departure.
signal on_ship_departure_cleared(ship : Ship)

## Registers a new ship with the ship manager.
func register_ship(ship : Ship):
	ships[ship.callsign] = ship

func unregister_ship(ship : Ship):
	ships.erase(ship.callsign)

func register_landing(landing_point : LandingPoint):
	landing_points.append(landing_point)

## Finds and returns the [Ship] with the specified callsign.
func find_ship(callsign : StringName):
	return ships[callsign]

## Returns a random spaceport on earth's surface
func get_random_port() -> LandingPoint:
	return landing_points[randi_range(0, landing_points.size()-1)]

## Returns a random spaceport without a ship awaiting takeoff
func get_random_free_port() -> LandingPoint:
	var free_count = 0
	for port in landing_points:
		if port.reservations.size() == 0:
			free_count = free_count + 1
	
	if free_count == 0:
		return null;
	
	var selection = randi_range(0, free_count-1)
	for port in landing_points:
		if port.reservations.size() == 0:
			if selection <= 0:
				return port
			selection = selection - 1
	
	assert(false)
	return null
