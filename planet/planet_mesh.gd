extends Node3D

func _process(delta):
	rotate_y(deg_to_rad(delta * 360 / ShipManager.day_length));
