extends Node

var ships : Dictionary = {}

## Registers a new ship with the ship manager.
func register_ship(ship : Ship):
	ships[ship.callsign] = ship

func unregister_ship(ship : Ship):
	ships.erase(ship.callsign)

## Finds and returns the [Ship] with the specified callsign.
func find_ship(callsign : StringName):
	return ships[callsign]
