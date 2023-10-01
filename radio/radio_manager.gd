extends Node

var controller_callsign = &"Approach"

## The current listener callsign for the open radio menu
var current_ui_callsign : StringName

## Signal emitted when a radio menu should be shown
signal on_show_menu(callsign : StringName, category_name : StringName)

## Signal emitted when a radio message is sent
signal on_message_sent(speaker_callsign : StringName, text : String)

## Shows the radio menu
func show_menu(callsign : StringName, category_name : StringName):
	if callsign.is_empty():
		callsign = current_ui_callsign
	else:
		current_ui_callsign = callsign
	on_show_menu.emit(callsign, category_name)

## Hides the radio menu
func hide_menu():
	current_ui_callsign = &""
	on_show_menu.emit(&"", &"")

func send_radio_player(to_callsign : StringName, message_name : StringName):
	var message_text = build_player_message_text(message_name, controller_callsign, to_callsign);
	on_message_sent.emit(controller_callsign, message_text)
	
	# wait for message
	await get_tree().create_timer(3).timeout #TODO: wait for narration
	
	# ship reaction
	var ship : Ship = ShipManager.find_ship(to_callsign)
	ship.receive_player_radio(message_name)

func send_radio_npc(from_callsign : StringName, message_text : String):
	print(message_text)
	on_message_sent.emit(from_callsign, message_text)

func deg_to_string(degrees : int) -> String:
	match degrees:
		0: return "zero"
		90: return "niner zero"
		180: return "one eight zero"
		270: return "two seven zero"
		_: return "unknown"

func build_player_message_text(message_name : StringName,
	from_callsign : StringName, to_callsign : StringName):
	var params = { "from": from_callsign, "to" : to_callsign}
	match message_name:
		&"GoAhead":
			return "{to} go ahead.".format(params)
		&"StandBy":
			return "{to} stand by.".format(params)
		&"SayIntentions":
			return "{to} say intentions.".format(params)
		&"AltTransfer.Ring1":
			return "{to} transfer to ring 1.".format(params)
		&"AltTransfer.Ring2":
			return "{to} transfer to ring 2.".format(params)
		&"AltTransfer.Ring3":
			return "{to} transfer to ring 3.".format(params)
		&"Takeoff.Prograde":
			return "{to}, cleared for prograde takeoff.".format(params)
		&"Takeoff.Retrograde":
			return "{to}, cleared for retrograde takeoff.".format(params)
		&"Departure.Direct.0":
			params["angle"] = RadioManager.deg_to_string(0)
			return build_direct_depart_text(params)
		&"Departure.Direct.90":
			params["angle"] = RadioManager.deg_to_string(90)
			return build_direct_depart_text(params)
		&"Departure.Direct.180":
			params["angle"] = RadioManager.deg_to_string(180)
			return build_direct_depart_text(params)
		&"Departure.Direct.270":
			params["angle"] = RadioManager.deg_to_string(270)
			return build_direct_depart_text(params)
		&"Departure.Slingshot.0":
			params["angle"] = RadioManager.deg_to_string(0)
			return build_slingshot_depart_text(params)
		&"Departure.Slingshot.90":
			params["angle"] = RadioManager.deg_to_string(90)
			return build_slingshot_depart_text(params)
		&"Departure.Slingshot.180":
			params["angle"] = RadioManager.deg_to_string(180)
			return build_slingshot_depart_text(params)
		&"Departure.Slingshot.270":
			params["angle"] = RadioManager.deg_to_string(270)
			return build_slingshot_depart_text(params)

func build_direct_depart_text(params):
	return "{to}, cleared for direct departure azimuth {angle}, good day.".format(params)

func build_slingshot_depart_text(params):
	return "{to}, cleared for slingshot departure azimuth {angle}, good day.".format(params)
