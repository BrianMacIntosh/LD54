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
	on_message_sent.emit(from_callsign, message_text)

func build_player_message_text(message_name : StringName,
	from_callsign : StringName, to_callsign : StringName):
	var params = { "from": from_callsign, "to" : to_callsign}
	match message_name:
		&"GoAhead":
			return "{to} go ahead.".format(params)
		&"StandBy":
			return "{to} stand by.".format(params)
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
		&"Departure.Direct":
			return "{to}, cleared for direct departure, good day.".format(params)
		&"Departure.Slingshot":
			return "{to}, cleared for slingshot departure, good day.".format(params)
