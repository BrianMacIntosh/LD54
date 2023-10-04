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

# The length of a day in seconds
var day_length : float = 180;

var infractions : int = 0
var infractions_max : int = 3

var dispatch_successes : int = 0
var cleared_departures : int = 0
var cleared_takeoffs : int = 0

## Signal emitted when a ship is correctly cleared for departure.
signal on_ship_departure_cleared(ship : Ship)

## Signal emitted when a ship is correctly cleared for takeoff.
signal on_ship_takeoff_cleared(ship : Ship)

## Signal emitted when an infraction is generated.
signal on_infraction(type : StringName, position : Vector3)

## Signal emitted when a ship is successfully dispatched.
signal on_dispatch_success(count : int)

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
		if ship1.tcas_enabled():
			for j in range(i+1, ships_flat.size()):
				var ship2 = ships_flat[j]
				if ship2.tcas_enabled():
					var dist_sq = ship1.global_position.distance_squared_to(ship2.global_position)
					if dist_sq < danger_radius * danger_radius:
						new_danger_pairs.append(DangerPair.new(ship1, ship2))
						if not has_danger_pair(ship1, ship2):
							issue_tcas_infraction(ship1, ship2)
	var temp = danger_pairs
	danger_pairs = new_danger_pairs
	temp.clear()
	old_danger_pairs = temp

func issue_tcas_infraction(ship1 : Ship, ship2 : Ship):
	infractions = infractions + 1
	RadioManager.send_radio_npc(&"TCAS", "[color=red]STCA conflict. Infraction issued.[/color]")
	var position = (ship1.global_position + ship2.global_position) / 2;
	on_infraction.emit(&"tcas", position)

func log_dispatch_success():
	dispatch_successes = dispatch_successes+1
	on_dispatch_success.emit(dispatch_successes)

func has_danger_pair(ship1 : Ship, ship2 : Ship) -> bool:
	for pair in danger_pairs:
		if pair.ship1 == ship1 and pair.ship2 == ship2 \
		or pair.ship2 == ship1 and pair.ship1 == ship2:
			return true
	return false

func reset():
	infractions = 0
	dispatch_successes = 0
	cleared_departures = 0
	cleared_takeoffs = 0

## Registers a new ship with the ship manager.
func register_ship(ship : Ship):
	ships[ship.callsign] = ship
	ships_flat.append(ship)

func unregister_ship(ship : Ship):
	ships.erase(ship.callsign)
	ships_flat.erase(ship)

func register_landing(landing_point : LandingPoint):
	landing_points.append(landing_point)

func unregister_landing(landing_point : LandingPoint):
	landing_points.erase(landing_point)

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
	
	#HACK: attempting to find breaking bug
	if landing_points.size() == 0:
		landing_points.append(get_tree().get_root().get_node("WorldRoot/planet/planet/Maracaibo"))
		landing_points.append(get_tree().get_root().get_node("WorldRoot/planet/planet/Johannesburg"))
		landing_points.append(get_tree().get_root().get_node("WorldRoot/planet/planet/Hyderabad"))
	assert(landing_points.size() > 0)
	
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
