@tool
extends Marker3D

@export var degrees : float : set = set_degrees, get = get_degrees
@export var radius : float = 4.25

func set_degrees(value):
	degrees = value
	$Anchor/Control/Label.text = str(degrees)

func get_degrees():
	return degrees

func _ready() -> void:
	$Anchor/Control/Label.text = str(degrees)
	$Anchor.position = radius * Vector3(cos(deg_to_rad(degrees)), 0, sin(deg_to_rad(degrees)))
	$Anchor/Control.update_position() #HACK
