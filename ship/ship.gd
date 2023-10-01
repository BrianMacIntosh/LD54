class_name Ship
extends Node3D

enum DepartureMode { Not, Waiting, Gone }

var altitude_change_rate : float = 0.1
var departure_burn_rate : float = 0.3

## This ship's unique callsign.
var callsign : StringName = Ship.generate_callsign()

var departure_velocity : Vector3 = Vector3()
var orbit_direction : float = 1 if randf() < 0.5 else -1
var target_altitude = 1
var departure_mode : DepartureMode = DepartureMode.Not
var cleared_depart_style : StringName = &""

var nav_origin = 0
var nav_origin_az = randi_range(0, 3) * 90
var nav_dest = randi_range(2, 3)
var nav_dest_az = randi_range(0, 3) * 90

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
	
	# Send initial welcome message
	await get_tree().create_timer(2).timeout
	RadioManager.send_radio_npc(callsign, build_text_intro())

func _exit_tree() -> void:
	ShipManager.unregister_ship(self)

func _process(delta):
	if get_altitude() <= 1 and target_altitude <= 1:
		process_landed(delta)
	elif departure_mode == DepartureMode.Gone:
		process_depart(delta)
	else:
		process_orbit(delta)
	
func process_landed(delta):
	pass

func process_depart(delta):
	if $DepartureBurnTimer.time_left > 0:
		departure_velocity += departure_velocity.normalized() * delta * departure_burn_rate
	
	# apply departure velocity
	global_position += departure_velocity * delta
	
	var to_planet : Vector3 = orbits.planet_node.global_position - global_position
	if to_planet.length_squared() > 10 * 10:
		queue_free()

func process_orbit(delta):
	var to_planet : Vector3 = orbits.planet_node.global_position - global_position
	var altitude = to_planet.length()
	var to_planet_dir = to_planet / altitude
	var altitude_delta = target_altitude - altitude
	
	# determine orbit tangent
	var tangent = to_planet_dir.cross(Vector3(0,orbit_direction,0))
	
	# change orbit altitude
	var alt_rate_mult_mag = clamp(abs(altitude_delta), 0, 1)
	alt_rate_mult_mag = 1 - pow(1 - alt_rate_mult_mag, 2)
	var alt_rate_mult = sign(altitude_delta) * alt_rate_mult_mag
	if departure_mode == DepartureMode.Gone:
		alt_rate_mult = 1
	global_position += -to_planet_dir * altitude_change_rate * alt_rate_mult * delta
	
	# orbit at the stable speed
	var stable_speed = orbits.get_orbital_speed(altitude)
	var stable_velocity = tangent * stable_speed
	global_position += stable_velocity * delta
	
	# check if able to depart
	if departure_mode == DepartureMode.Waiting:
		var azimuth = fmod(360 + rad_to_deg(atan2(-to_planet_dir.z, -to_planet_dir.x)), 360)
		var angle_distance = min(abs(nav_dest_az - azimuth), abs(nav_dest_az + 360 - azimuth))
		if angle_distance < 20:
			departure_mode = DepartureMode.Gone
			departure_velocity = stable_velocity
			$DepartureBurnTimer.start()

func get_altitude() -> float:
	var to_planet : Vector3 = orbits.planet_node.global_position - global_position;
	return to_planet.length()

func is_landed() -> bool:
	var alt = get_altitude()
	return alt <= 1

func generate_reaction_time() -> float:
	return randf() * 4 + 1

func receive_player_radio(message : StringName):
	await get_tree().create_timer(generate_reaction_time()).timeout
	match message:
		&"GoAhead":
			pass
		&"StandBy":
			pass
		&"SayIntentions":
			receive_say_intentions()
		&"AltTransfer.Ring1":
			receive_transfer(1)
		&"AltTransfer.Ring2":
			receive_transfer(2)
		&"AltTransfer.Ring3":
			receive_transfer(3)
		&"Takeoff.Prograde":
			receive_takeoff(&"prograde")
		&"Takeoff.Retrograde":
			receive_takeoff(&"retrograde")
		&"Departure.Direct.0":
			receive_departure(&"direct", 0)
		&"Departure.Direct.90":
			receive_departure(&"direct", 90)
		&"Departure.Direct.180":
			receive_departure(&"direct", 180)
		&"Departure.Direct.270":
			receive_departure(&"direct", 270)
		&"Departure.Slingshot.0":
			receive_departure(&"slingshot", 0)
		&"Departure.Slingshot.90":
			receive_departure(&"slingshot", 90)
		&"Departure.Slingshot.180":
			receive_departure(&"slingshot", 180)
		&"Departure.Slingshot.270":
			receive_departure(&"slingshot", 270)

#TODO: cache
func get_format_params():
	return {
		"callsign": str(callsign),
		"cleared_depart_style": str(cleared_depart_style),
		"nav_dest_az": RadioManager.deg_to_string(nav_dest_az),
		"nav_dest": ring_index_to_name(nav_dest)
	}

func ring_index_to_name(ring_index : int) -> String:
	match ring_index:
		1: return "ring one" if randf() < 0.8 else "LEO"
		2: return "ring two"
		3: return "ring three"
		_: return "UNKNOWN"

func receive_say_intentions():
	RadioManager.send_radio_npc(callsign, build_text_intentions())

func receive_transfer(ring_index : int):
	if is_landed():
		RadioManager.send_radio_npc(callsign, build_text_alt_decline_landed(ring_index))
	else:
		target_altitude = orbits.ring_to_altitude(ring_index)
		RadioManager.send_radio_npc(callsign, build_text_alttransfer(ring_index))

func receive_takeoff(in_direction : StringName):
	if not is_landed():
		RadioManager.send_radio_npc(callsign, build_text_takeoff_decline_landed(in_direction))
	else:
		RadioManager.send_radio_npc(callsign, build_text_takeoff(in_direction))
		await get_tree().create_timer(2).timeout
		target_altitude = orbits.ring_to_altitude(1)
		orbit_direction = 1 if in_direction == &"prograde" else -1

func receive_departure(in_style : StringName, degrees : int):
	if is_landed():
		RadioManager.send_radio_npc(callsign, build_text_depart_decline_landed(in_style, degrees))
	elif target_altitude != nav_dest + 1: #HACK: track rings
		RadioManager.send_radio_npc(callsign, build_text_depart_decline_wrong_alt(in_style, degrees))
	elif degrees != nav_dest_az:
		RadioManager.send_radio_npc(callsign, build_text_depart_decline_wrong_deg(in_style, degrees))
	else:
		cleared_depart_style = in_style
		RadioManager.send_radio_npc(callsign, build_text_depart(in_style, degrees))
		await get_tree().create_timer(1).timeout
		departure_mode = DepartureMode.Waiting

func build_text_intentions():
	if departure_mode == DepartureMode.Waiting:
		return "{callsign} {cleared_depart_style} departure as cleared {nav_dest_az} degrees.".format(get_format_params())
	elif is_landed():
		return "%s requesting takeoff to LEO from %s." % [ callsign, "LOCATION" ]
	else:
		return "{callsign} would like to depart at {nav_dest_az} degrees from {nav_dest}".format(get_format_params())

func build_text_alt_decline_landed(_ring_index : int):
	return "Control, negative transfer, we're still on the ground."

func build_text_alttransfer(ring_index : int):
	return "Transfering to %s, %s" % [ ring_index_to_name(ring_index), callsign ]

func build_text_intro():
	if nav_origin == 0:
		return "%s requesting takeoff to LEO from %s." % [ callsign, "LOCATION" ]
	else:
		return "Good day, {callsign} inbound to earth requesting ring three.".format(get_format_params())

func build_text_takeoff_decline_landed(_in_direction : StringName):
	return "Control, negative takeoff, we're already in the air."

func build_text_takeoff(in_direction : StringName):
	var params = get_format_params()
	params["takeoff_style"] = in_direction
	return "Cleared for {takeoff_style} takeoff, {callsign}.".format(params)
	
func build_text_depart_decline_landed(_in_style, _degrees):
	return "Control, negative departure, we're still on the ground."

func build_text_depart_decline_wrong_deg(_in_style, degrees):
	var params = get_format_params()
	params["degrees"] = RadioManager.deg_to_string(degrees)
	return "Control, negative {degrees} degrees, we need {nav_dest_az}.".format(params)

func build_text_depart_decline_wrong_alt(_in_style, degrees):
	var params = get_format_params()
	return "Control, negative departure, we need {nav_dest}.".format(params)

func build_text_depart(in_style, degrees):
	var params = get_format_params()
	return "{callsign} cleared for {cleared_depart_style} departure {nav_dest_az} degrees.".format(params)
