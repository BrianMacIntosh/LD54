extends Label

func _ready() -> void:
	ShipManager.on_infraction.connect(handle_infraction)
	update_label()

func handle_infraction(type : StringName, position : Vector3):
	update_label()

func update_label():
	var count = max(0, ShipManager.infractions_max - ShipManager.infractions)
	text = "Infractions Remaining: %d" % count
