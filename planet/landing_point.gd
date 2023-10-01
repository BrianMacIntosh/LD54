class_name LandingPoint
extends Marker3D

@export var display_name : String
@export var port_code : String

var reservations : Array = []

func _ready() -> void:
	$Control/Label.text = port_code

func _enter_tree() -> void:
	ShipManager.register_landing(self)

func _exit_tree() -> void:
	ShipManager.unregister_landing(self)
