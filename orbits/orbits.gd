class_name Orbits
extends Node3D

## Altitude of the planet surface
@export var altitude_surface : float = 1

var G = 6.67e-11
@export var planet_mass : float = 9e8

@export var ship_spawn_interval : float = 5

@onready var ship_prefab = preload("res://ship/base_ship.tscn")
@onready var planet_node = get_tree().get_root().get_node("WorldRoot/planet")

## Returns the world altitude of the specified ring
func ring_to_altitude(ring : int) -> float:
	return ring + altitude_surface

func create_ship() -> Ship:
	var new_ship = ship_prefab.instantiate()
	return new_ship

func co_spawn_ships():
	
	#DEBUG
	#Engine.time_scale = 3
	
	var ship : Ship
	print("Begin co_spawn_ships.");
	await get_tree().create_timer(1).timeout
	
	#TEMP TEST
	#ship = create_ship()
	#ship.generate_arrival(self)
	#return

	# Initial ship
	print("Spawning tutorial ship 1...");
	ship = create_ship()
	print("Generating parameters for tutorial ship 1...");
	ship.generate_departure(self)
	print("Tutorial ship 1 spawned.");

	print("Waiting for departure to clear...");
	await ShipManager.on_ship_departure_cleared
	print("Departure cleared. Waiting 2 seconds...");
	await get_tree().create_timer(2).timeout

	# Second ship: after departure
	print("Spawning tutorial ship 2...");
	ship = create_ship()
	print("Generating parameters for tutorial ship 2...");
	ship.generate_departure(self)
	print("Tutorial ship 2 spawned.");

	print("Waiting for takeoff to clear...");
	while ShipManager.cleared_takeoffs < 2:
		await get_tree().process_frame
	#await ShipManager.on_ship_takeoff_cleared
	print("Takeoff cleared. Waiting 2 seconds...");
	await get_tree().create_timer(2).timeout

	# A couple more ships: after takeoff
	var counter = 3
	print("Spawning more landed ships...");
	while counter > 0:
		print("Spawning ship...%d remaining" % counter);
		ship = create_ship()
		print("Ship spawned.");
		if ship.generate_departure(self):
			print("Departure parameters generated.");
			counter = counter - 1
			print("Waiting a while to spawn next ship...");
			await get_tree().create_timer(randf_range(17, 21)).timeout
			print("Done waiting.")

	# Arriving ship
	print("Spawning an arriving ship...")
	ship = create_ship()
	ship.generate_arrival(self)
	
	# Full random
	while true:
		var wait_base = 4 + 30/max(1, sqrt(ShipManager.dispatch_successes))
		await get_tree().create_timer(randf_range(wait_base, wait_base*1.2)).timeout
		ship = create_ship()
		if randf() < 0.3:
			ship.generate_arrival(self)
		else:
			ship.generate_departure(self)

func get_gravity_accel(radius : float):
	return G * planet_mass / (radius * radius);

func get_orbital_speed(radius : float):
	return sqrt(G * planet_mass / radius);
