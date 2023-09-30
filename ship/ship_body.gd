extends StaticBody3D

var mouse_inside : bool = false

func _input_event(camera, event, position, normal, shape_idx):
	if mouse_inside:
		print(event.as_text())

func _mouse_enter():
	mouse_inside = true

func _mouse_exit():
	mouse_inside = false
