extends Control
## From Godot demo Waypoints project

@onready var camera = get_viewport().get_camera_3d()
@onready var parent = get_parent()

func _ready() -> void:
	if not parent is Node3D:
		push_error("The waypoint's parent node must inherit from Node3D.")
	update_position()

func _process(_delta):
	update_position()

func update_position():
	if not camera.current:
		# If the camera we have isn't the current one, get the current camera.
		camera = get_viewport().get_camera_3d()
	var parent_position = parent.global_transform.origin
	position = camera.unproject_position(parent_position)
