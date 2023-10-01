extends Control
## From Godot demo Waypoints project

@export var is_static : bool = false

@onready var camera = get_viewport().get_camera_3d()
@onready var parent = get_parent()

func _ready() -> void:
	if not parent is Node3D:
		push_error("The waypoint's parent node must inherit from Node3D.")
	update_position()
	if is_static:
		set_process(false)

func _process(_delta):
	update_position()

func update_position():
	if not camera.current:
		# If the camera we have isn't the current one, get the current camera.
		camera = get_viewport().get_camera_3d()
	var parent_position = parent.global_transform.origin
	var camera_transform = camera.global_transform
	var camera_position = camera_transform.origin
	
	# We would use "camera.is_position_behind(parent_position)", except
	# that it also accounts for the near clip plane, which we don't want.
	var is_behind = camera_transform.basis.z.dot(parent_position - camera_position) > 0
	
	var unprojected_position = camera.unproject_position(parent_position)
	
	position = unprojected_position
	visible = not is_behind
