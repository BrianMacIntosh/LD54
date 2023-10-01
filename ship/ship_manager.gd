extends Node

var ships : Dictionary = {}
var ships_flat : Array = []
var landing_points : Array = []

class DangerPair:
	var ship1 : Ship
	var ship2 : Ship
	
	func _init(in_ship1 : Ship, in_ship2 : Ship):
		ship1 = in_ship1
		ship2 = in_ship2

var danger_pairs : Array = []
var old_danger_pairs : Array = []
var danger_radius : float = 0.5

var infractions : int = 0
var infractions_max : int = 3

## Signal emitted when a ship is correctly cleared for departure.
signal on_ship_departure_cleared(ship : Ship)

## Signal emitted when a ship is correctly cleared for takeoff.
signal on_ship_takeoff_cleared(ship : Ship)

## Signal emitted when an infraction is generated.
signal on_infraction(type : StringName)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("SelectShip"):
		RadioManager.hide_menu()

func _ready() -> void:
	co_test_distance_infractions()

func co_test_distance_infractions() -> void:
	while is_inside_tree():
		await get_tree().create_timer(0.2).timeout
		test_distance_infractions()

func test_distance_infractions():
	var new_danger_pairs = old_danger_pairs
	for i in range(ships_flat.size()):
		var ship1 = ships_flat[i]
		for j in range(i+1, ships_flat.size()):
			var ship2 = ships_flat[j]
			var dist_sq = ship1.global_position.distance_squared_to(ship2.global_position)
			if dist_sq < danger_radius:
				new_danger_pairs.append(DangerPair.new(ship1, ship2))
				if not has_danger_pair(ship1, ship2):
					infractions = infractions + 1
					on_infraction.emit(&"danger_radius")
	var temp = danger_pairs
	danger_pairs = new_danger_pairs
	temp.clear()
	old_danger_pairs = temp

func has_danger_pair(ship1 : Ship, ship2 : Ship) -> bool:
	for pair in danger_pairs:
		if pair.ship1 == ship1 and pair.ship2 == ship2 \
		or pair.ship2 == ship1 and pair.ship1 == ship2:
			return true
	return false

## Registers a new ship with the ship manager.
func register_ship(ship : Ship):
	ships[ship.callsign] = ship
	ships_flat.append(ship)

func unregister_ship(ship : Ship):
	ships.erase(ship.callsign)
	ships_flat.erase(ship)

func register_landing(landing_point : LandingPoint):
	landing_points.append(landing_point)

## Finds and returns the [Ship] with the specified callsign.
func find_ship(callsign : StringName):
	if ships.has(callsign):
		return ships[callsign]
	else:
		return null

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
