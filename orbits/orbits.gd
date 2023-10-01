class_name Orbits
extends Node3D

## Altitude of the planet surface
@export var altitude_surface : float = 1;

var G = 6.67e-11
@export var planet_mass : float = 8e8;

@export var ship_spawn_interval : float = 5;

@onready var ship_prefab = preload("res://ship/base_ship.tscn")
@onready var planet_node = get_tree().get_root().get_node("WorldRoot/planet");

## Returns the world altitude of the specified ring
func ring_to_altitude(ring : int) -> float:
	return ring + altitude_surface

func _ready():
	co_spawn_ships()

func co_spawn_ships():
	print("co_spawn_ships is starting.")
	while true:
		var new_ship = ship_prefab.instantiate();
		add_child(new_ship);
		new_ship.position = Vector3(altitude_surface, 0, 0);
		print("Ship spawned.");
		await get_tree().create_timer(ship_spawn_interval).timeout;
		return

func get_gravity_accel(radius : float):
	return G * planet_mass / (radius * radius);

func get_orbital_speed(radius : float):
	return sqrt(G * planet_mass / radius);
