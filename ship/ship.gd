extends Node3D

@export var altitude_change_rate : float = 0.1;

## This ship's unique callsign.
var callsign : StringName = generate_callsign()

var velocity : Vector3 = Vector3()
var target_altitude = 2;

@onready var orbits = get_tree().get_root().get_node("WorldRoot/orbits");

static func generate_callsign() -> String:
	var callsign : String = "";
	callsign += char(randi_range('A'.unicode_at(0), 'Z'.unicode_at(0)))
	callsign += char(randi_range('A'.unicode_at(0), 'Z'.unicode_at(0)))
	callsign += char(randi_range('0'.unicode_at(0), '9'.unicode_at(0)))
	callsign += char(randi_range('0'.unicode_at(0), '9'.unicode_at(0)))
	callsign += char(randi_range('0'.unicode_at(0), '9'.unicode_at(0)))
	return callsign

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
	var alt_rate_mult_mag = abs(altitude_delta)
	alt_rate_mult_mag = 1 - pow(1 - alt_rate_mult_mag, 2)
	var alt_rate_mult = sign(altitude_delta) * alt_rate_mult_mag
	global_position += -to_planet_dir * altitude_change_rate * alt_rate_mult * delta;
	
	# orbit at the stable speed
	var stable_speed = orbits.get_orbital_speed(altitude);
	global_position += tangent * stable_speed * delta;
	
	# apply velocity
	global_position += velocity * delta;
