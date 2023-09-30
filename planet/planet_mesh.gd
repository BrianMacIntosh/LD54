extends Node3D

# The length of a day in seconds
@export var day_length : float = 60;

func _ready():
	pass # Replace with function body.

func _process(delta):
	$planet.rotate_y(deg_to_rad(delta * 360 / day_length));
