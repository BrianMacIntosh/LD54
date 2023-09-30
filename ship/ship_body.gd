extends StaticBody3D

@onready var ship_owner = get_parent()

func _input_event(camera, event, position, normal, shape_idx):
	if event.is_action("SelectShip"):
		RadioManager.show_menu(ship_owner.callsign, "RadioRoot")

func _mouse_enter():
	pass

func _mouse_exit():
	pass
