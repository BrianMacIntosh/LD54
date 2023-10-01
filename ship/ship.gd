class_name Ship
extends Node3D

enum DepartureMode { Not, Waiting, Gone }

var altitude_change_rate : float = 0.1
var departure_burn_rate : float = 0.15

## This ship's unique callsign.
var callsign : StringName = Ship.generate_callsign()

var departure_velocity : Vector3 = Vector3()
var orbit_direction : float = 1 if randf() < 0.5 else -1
var target_altitude = 1
var alt_rate_mult = 0
var departure_mode : DepartureMode = DepartureMode.Not
var cleared_depart_style : StringName = &""
var landing_mode : DepartureMode = DepartureMode.Not

class DepartureInfo:
	var azimuth : int
	var ring : int

class PortInfo:
	var landing_point

var nav_origin
var nav_dest

@onready var orbits : Orbits = get_tree().get_root().get_node("WorldRoot/orbits");
@onready var danger_radius_mesh = $DangerRadiusMesh

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
	$Control/CallsignLabel.text = callsign
	danger_radius_mesh.radius = ShipManager.danger_radius
	set_selected(false)
	
	# Send initial welcome message
	await get_tree().create_timer(2).timeout
	RadioManager.send_radio_npc(callsign, build_text_intro())

func _enter_tree() -> void:
	ShipManager.register_ship(self)

func _exit_tree() -> void:
	ShipManager.unregister_ship(self)
	
	if nav_origin is PortInfo:
		nav_origin.landing_point.reservations.erase(self)

func _process(delta):
	
	#HACK
	danger_radius_mesh.visible = tcas_enabled()
	
	if landing_mode == DepartureMode.Gone:
		process_orbit(delta)
	elif get_altitude() <= 1 and target_altitude <= 1:
		pass #on ground
	elif departure_mode == DepartureMode.Gone:
		process_depart(delta)
	else:
		process_orbit(delta)

func process_depart(delta):
	departure_velocity += departure_velocity.normalized() * delta * departure_burn_rate
	$EngineFlareScaler.scale = Vector3.ONE * min(1, departure_velocity.length())
	
	var old_to_planet : Vector3 = orbits.planet_node.global_position - global_position
	var old_dist_sq = old_to_planet.length_squared()
	
	# apply departure velocity
	global_position += departure_velocity * delta
	
	var new_to_planet : Vector3 = orbits.planet_node.global_position - global_position
	var new_dist_sq = new_to_planet.length_squared()
	
	if old_dist_sq < 4.5 * 4.5 and new_dist_sq >= 4.5 * 4.5:
		ShipManager.log_dispatch_success()
	if new_dist_sq > 10 * 10:
		queue_free()

func process_orbit(delta):
	var to_planet : Vector3 = orbits.planet_node.global_position - global_position
	var altitude = to_planet.length()
	var to_planet_dir = to_planet / altitude
	var altitude_delta = target_altitude - altitude
	
	# determine orbit tangent
	var tangent = to_planet_dir.cross(Vector3(0,orbit_direction,0))
	
	# arrival speed boost
	var arrival_factor = max(0, altitude - orbits.ring_to_altitude(3))
	var arrival_speed_mult = 1 + arrival_factor
	
	# change orbit altitude
	var alt_rate_mult_mag = clamp(abs(altitude_delta), 0, 1)
	alt_rate_mult_mag = 1 - pow(1 - alt_rate_mult_mag, 2)
	var target_alt_rate_mult = sign(altitude_delta) * alt_rate_mult_mag
	if departure_mode == DepartureMode.Gone:
		target_alt_rate_mult = 1
	alt_rate_mult = move_toward(alt_rate_mult, target_alt_rate_mult, delta) 
	global_position += -to_planet_dir * altitude_change_rate * alt_rate_mult * delta * arrival_speed_mult
	
	# orbit at the stable speed
	var stable_speed = orbits.get_orbital_speed(altitude)
	var stable_velocity = tangent * stable_speed
	global_position += stable_velocity * delta * arrival_speed_mult
	
	# check if able to depart
	var azimuth = fmod(360 + rad_to_deg(atan2(-to_planet_dir.z, -to_planet_dir.x)), 360)
	if departure_mode == DepartureMode.Waiting and abs(altitude_delta) < 0.3:
		var angle_distance = min(abs(nav_dest.azimuth - azimuth), abs(nav_dest.azimuth + 360 - azimuth))
		if angle_distance < 20:
			departure_mode = DepartureMode.Gone
			departure_velocity = stable_velocity
	
	#check if able to land
	if landing_mode == DepartureMode.Waiting:
		var time_to_ground = (altitude-1) / altitude_change_rate
		
		#predict where target will be at the landing time
		var target_pos = nav_dest.landing_point.global_position
		var target_az = rad_to_deg(atan2(target_pos.z, target_pos.x))
		var planet_rot_speed = 1 / ShipManager.day_length
		var target_future_az = target_az + time_to_ground * planet_rot_speed
		
		#predict where I need to depart from
		var current_circumference = 2 * PI * altitude
		var surface_circumference = 2 * PI * 1
		var current_rot_speed = 360 / (current_circumference / stable_speed)
		var surface_rot_speed = 360 / (surface_circumference / orbits.get_orbital_speed(1))
		var avg_rot_speed = (current_rot_speed + surface_rot_speed) / 2
		var depart_az = target_future_az - avg_rot_speed * time_to_ground
		depart_az = fmod(720 + depart_az, 360)
		#HACK: BIG HACK
		if orbit_direction < 0:
			depart_az = fmod(depart_az + 270, 360)
		else:
			depart_az = fmod(depart_az + 180, 360)
		#HACK
		var depart_delta = min(abs(depart_az - azimuth),
							   abs(depart_az + 360 - azimuth),
							   abs(depart_az - azimuth - 360))
		if depart_delta < 10:
			landing_mode = DepartureMode.Gone
			target_altitude = 0
	elif landing_mode == DepartureMode.Gone:
		if altitude <= 1:
			ShipManager.log_dispatch_success()
			queue_free()
	
	# flare
	$EngineFlareScaler.scale = Vector3.ONE * min(1, max(abs(alt_rate_mult), arrival_factor))

func tcas_enabled() -> bool:
	return not is_landed()

func set_selected(state : bool):
	$SelectedMesh.visible = state

## Returns true on success.
func generate_departure(sender : Orbits) -> bool:
	var port = ShipManager.get_random_free_port()
	if port == null:
		queue_free()
		return false
	
	nav_origin = PortInfo.new()
	nav_origin.landing_point = port
	nav_dest = DepartureInfo.new()
	nav_dest.azimuth = randi_range(0, 3) * 90
	nav_dest.ring = randi_range(2, 3)
	
	if not port.reservations.has(self):
		port.reservations.append(self)
	port.add_child(self)
	position = Vector3.ZERO
	
	return true

## Returns true on success.
func generate_arrival(sender : Orbits) -> bool:
	nav_origin = DepartureInfo.new()
	nav_origin.azimuth = randi_range(0, 1) * 180
	nav_origin.ring = 4
	nav_dest = PortInfo.new()
	nav_dest.landing_point = ShipManager.get_random_port()
	orbit_direction = -1 if randf() < 0.5 else 1
	
	var spawn_az = nav_origin.azimuth + orbit_direction * 65
	position = 15 * Vector3(cos(deg_to_rad(spawn_az)), 0, sin(deg_to_rad(spawn_az)))
	sender.add_child(self)
	target_altitude = orbits.ring_to_altitude(3)
	
	return true;

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
		&"Landing.Maracaibo":
			receive_landing(&"Maracaibo")
		&"Landing.Johannesburg":
			receive_landing(&"Johannesburg")
		&"Landing.Hyderabad":
			receive_landing(&"Hyderabad")

#TODO: cache
func get_format_params():
	var params = {
		"callsign": str(callsign),
		"cleared_depart_style": str(cleared_depart_style)
	}
	
	if nav_dest is DepartureInfo:
		params["nav_dest_az"] = RadioManager.deg_to_string(nav_dest.azimuth)
		params["nav_dest"] = ring_index_to_name(nav_dest.ring)
	elif nav_dest is PortInfo:
		params["nav_dest"] = nav_dest.landing_point.display_name
	
	if nav_origin is DepartureInfo:
		params["nav_origin_az"] = RadioManager.deg_to_string(nav_origin.azimuth)
		params["nav_origin"] = ring_index_to_name(nav_origin.ring)
	elif nav_origin is PortInfo:
		params["nav_origin"] = nav_origin.landing_point.display_name
	
	return params

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
		departure_mode = DepartureMode.Not
		RadioManager.send_radio_npc(callsign, build_text_alttransfer(ring_index))

func receive_takeoff(in_direction : StringName):
	if not is_landed():
		RadioManager.send_radio_npc(callsign, build_text_takeoff_decline_landed(in_direction))
	else:
		RadioManager.send_radio_npc(callsign, build_text_takeoff(in_direction))
		ShipManager.on_ship_takeoff_cleared.emit(self)
		await get_tree().create_timer(2).timeout
		target_altitude = orbits.ring_to_altitude(1)
		orbit_direction = 1 if in_direction == &"prograde" else -1
		nav_origin.landing_point.reservations.erase(self)
		var prev_pos = global_position
		get_parent().remove_child(self)
		orbits.add_child(self)
		set_owner(orbits)
		global_position = prev_pos

func receive_departure(in_style : StringName, degrees : int):
	if nav_dest is PortInfo:
		RadioManager.send_radio_npc(callsign, build_text_depart_decline_arriving())
	elif is_landed():
		RadioManager.send_radio_npc(callsign, build_text_depart_decline_landed(in_style, degrees))
	elif target_altitude != nav_dest.ring + 1: #HACK: track rings
		RadioManager.send_radio_npc(callsign, build_text_depart_decline_wrong_alt(in_style, degrees))
	elif degrees != nav_dest.azimuth:
		RadioManager.send_radio_npc(callsign, build_text_depart_decline_wrong_deg(in_style, degrees))
	else:
		cleared_depart_style = in_style
		RadioManager.send_radio_npc(callsign, build_text_depart(in_style, degrees))
		ShipManager.on_ship_departure_cleared.emit(self)
		await get_tree().create_timer(1).timeout
		departure_mode = DepartureMode.Waiting

func receive_landing(port : StringName):
	if is_landed():
		RadioManager.send_radio_npc(callsign, build_text_landing_declined_ground())
	elif nav_dest is PortInfo:
		if port == nav_dest.landing_point.name:
			RadioManager.send_radio_npc(callsign, build_text_landing_cleared())
			await get_tree().create_timer(1).timeout
			landing_mode = DepartureMode.Waiting
		else:
			RadioManager.send_radio_npc(callsign, build_text_landing_wrong_port(port))
	elif nav_dest is DepartureInfo:
		RadioManager.send_radio_npc(callsign, build_text_landing_declined_departing())
	else:
		assert(false)

func build_text_landing_declined_ground():
	var params = get_format_params()
	return "Negative landing, control, we're already on the ground. {callsign}.".format(params)

func build_text_landing_cleared():
	var params = get_format_params()
	return "Cleared to land {nav_dest}. {callsign}.".format(params)

func build_text_landing_wrong_port(port : StringName):
	var params = get_format_params()
	params["cleared_dest"] = port
	return "Negative {cleared_dest} for {callsign}, we need {nav_dest}.".format(params)

func build_text_landing_declined_departing():
	var params = get_format_params()
	return "Negative landing, control, we need to depart {nav_dest}. {callsign}.".format(params)

func build_text_intentions():
	if departure_mode == DepartureMode.Waiting:
		return "{callsign} {cleared_depart_style} departure as cleared {nav_dest_az} degrees.".format(get_format_params())
	elif landing_mode == DepartureMode.Waiting:
		return "{callsign} landing at {nav_dest} as cleared.".format(get_format_params())
	elif is_landed():
		return "%s requesting takeoff to LEO from %s." % [ callsign, "LOCATION" ]
	elif nav_dest is DepartureInfo:
		return "{callsign} would like to depart at {nav_dest_az} degrees from {nav_dest}".format(get_format_params())
	elif nav_dest is PortInfo:
		return "{callsign} would like to land at {nav_dest}.".format(get_format_params())
	else:
		assert(false)
		return "ERROR"
		

func build_text_alt_decline_landed(_ring_index : int):
	return "Control, negative transfer, we're still on the ground."

func build_text_alttransfer(ring_index : int):
	return "Transfering to %s, %s" % [ ring_index_to_name(ring_index), callsign ]

func build_text_intro():
	var params = get_format_params()
	if nav_origin is PortInfo:
		return "{callsign} requesting takeoff to LEO from {nav_origin}.".format(params)
	else:
		return "Good day, {callsign} inbound to ring three at {nav_origin_az} degrees.".format(params)

func build_text_depart_decline_arriving():
	var params = get_format_params()
	return "Control, negative departure, we're inbound for {nav_dest}.".format(params)

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

func build_text_depart_decline_wrong_alt(_in_style, _degrees):
	var params = get_format_params()
	return "Control, negative departure, we need {nav_dest}.".format(params)

func build_text_depart(_in_style, _degrees):
	var params = get_format_params()
	return "{callsign} cleared for {cleared_depart_style} departure {nav_dest_az} degrees.".format(params)
