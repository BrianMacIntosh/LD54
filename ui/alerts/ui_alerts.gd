extends Control

@onready var tcas_alert_prefab = preload("res://ui/alerts/ui_alert_tcas.tscn")

func _ready() -> void:
	ShipManager.on_infraction.connect(handle_infraction)

func handle_infraction(type : StringName, position : Vector3):
	var new_alert = tcas_alert_prefab.instantiate()
	add_child(new_alert)
	new_alert.position = world_to_canvas(position)

func world_to_canvas(position : Vector3):
	var camera = get_viewport().get_camera_3d()
	return camera.unproject_position(position)
