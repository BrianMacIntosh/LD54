extends Node

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

func send_radio_player(message_name : StringName):
	pass

func send_radio_npc():
	pass
