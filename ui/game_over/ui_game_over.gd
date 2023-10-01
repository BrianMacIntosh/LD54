extends Control

func _ready() -> void:
	visible = false
	ShipManager.on_infraction.connect(handle_infraction)

func handle_infraction(type : StringName, position : Vector3):
	if ShipManager.infractions >= ShipManager.infractions_max:
		visible = true
