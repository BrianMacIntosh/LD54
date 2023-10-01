extends Button

func _pressed() -> void:
	get_owner().visible = false
	
	var orbits : Orbits = get_tree().get_root().get_node("WorldRoot/orbits")
	orbits.co_spawn_ships()
