class_name Ship
extends Node3D

@export var altitude_change_rate : float = 0.1;

## This ship's unique callsign.
var callsign : StringName = generate_callsign()

var velocity : Vector3 = Vector3()
var target_altitude = 2;

@onready var orbits : Orbits = get_tree().get_root().get_node("WorldRoot/orbits");

## Generates a random ship callsign
static func generate_callsign() -> String:
	var new_sign : String = "";
	new_sign += char(randi_range('A'.unicode_at(0), 'Z'.unicode_at(0)))
	new_sign += char(randi_range('A'.unicode_at(0), 'Z'.unicode_at(0)))
	new_sign += char(randi_range('0'.unicode_at(0), '9'.unicode_at(0)))
	new_sign += char(randi_range('0'.unicode_at(0), '9'.unicode_at(0)))
	new_sign += char(randi_range('0'.unicode_at(0), '9'.unicode_at(0)))
	return new_sign

func _ready() -> void:
	ShipManager.register_ship(self)
	$Control/CallsignLabel.text = callsign

func _exit_tree() -> void:
	ShipManager.unregister_ship(self)

func _process(delta):
	
	var to_planet : Vector3 = orbits.planet_node.global_position - global_position;
	var altitude = to_planet.length();
	var to_planet_dir = to_planet / altitude;
	var speed = velocity.length();
	var altitude_delta = target_altitude - altitude;
	
	# determine orbit tangent
	var tangent = to_planet_dir.cross(Vector3(0,1,0));
	var tangent_speed = velocity.dot(tangent);
	if tangent_speed < 0:
		tangent *= -1;
		tangent_speed *= -1;
	
	var direction = velocity / speed if speed > 0 else tangent;
	
	# change orbit altitude
	var alt_rate_mult_mag = clamp(abs(altitude_delta), 0, 1)
	alt_rate_mult_mag = 1 - pow(1 - alt_rate_mult_mag, 2)
	var alt_rate_mult = sign(altitude_delta) * alt_rate_mult_mag
	global_position += -to_planet_dir * altitude_change_rate * alt_rate_mult * delta;
	
	# orbit at the stable speed
	var stable_speed = orbits.get_orbital_speed(altitude);
	global_position += tangent * stable_speed * delta;
	
	# apply velocity
	global_position += velocity * delta;

func generate_reaction_time() -> float:
	return randf() * 4 + 1

func receive_player_radio(message : StringName):
	await get_tree().create_timer(generate_reaction_time()).timeout
	match message:
		&"GoAhead":
			pass
		&"StandBy":
			pass
		&"AltTransfer.Ring1":
			target_altitude = orbits.ring_to_altitude(1)
			RadioManager.send_radio_npc(callsign, build_text_alttransfer(1))
		&"AltTransfer.Ring2":
			target_altitude = orbits.ring_to_altitude(2)
			RadioManager.send_radio_npc(callsign, build_text_alttransfer(2))
		&"AltTransfer.Ring3":
			target_altitude = orbits.ring_to_altitude(3)
			RadioManager.send_radio_npc(callsign, build_text_alttransfer(3))
		&"Takeoff.Prograde":
			pass
		&"Takeoff.Retrograde":
			pass
		&"Departure.Direct":
			pass
		&"Departure.Slingshot":
			pass

func build_text_alttransfer(ring_index : int):
	var ring_name
	match ring_index:
		1: ring_name = "ring one" if randf() < 0.8 else "LEO"
		2: ring_name = "ring two"
		3: ring_name = "ring three"
	return "Transfering to %s, %s" % [ ring_name, callsign ]
