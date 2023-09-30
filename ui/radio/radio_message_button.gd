extends Button
## A button that sends a radio message when clicked.

## The name of the message to send.
@export var message_identifier : StringName

func _pressed():
	RadioManager.send_radio_player(message_identifier)
	RadioManager.hide_menu()
