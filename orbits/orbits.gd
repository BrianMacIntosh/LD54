class_name Orbits
extends Node3D

## Altitude of the planet surface
@export var altitude_surface : float = 1;

var G = 6.67e-11
@export var planet_mass : float = 9e8;

@export var ship_spawn_interval : float = 5;

@onready var ship_prefab = preload("res://ship/base_ship.tscn")
@onready var planet_node = get_tree().get_root().get_node("WorldRoot/planet");

## Returns the world altitude of the specified ring
func ring_to_altitude(ring : int) -> float:
	return ring + altitude_surface

func _ready():
	co_spawn_ships()

func create_ship():
	var new_ship = ship_prefab.instantiate()
	return new_ship

func co_spawn_ships():
	
	await get_tree().create_timer(1).timeout
	
	# Initial ship
	var ship1 : Ship = create_ship()
	ship1.generate_departure()
	
	await ShipManager.on_ship_departure_cleared
	
	# Second ship
	var ship2 = create_ship()
	ship2.generate_departure()

func get_gravity_accel(radius : float):
	return G * planet_mass / (radius * radius);

func get_orbital_speed(radius : float):
	return sqrt(G * planet_mass / radius);
