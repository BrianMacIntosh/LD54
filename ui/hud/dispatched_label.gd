extends Label

func _ready() -> void:
	ShipManager.on_dispatch_success.connect(handle_dispatch_success)

func handle_dispatch_success(count : int):
	text = "Ships Dispatched: %d" % count
