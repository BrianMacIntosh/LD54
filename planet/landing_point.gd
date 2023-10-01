class_name LandingPoint
extends Marker3D

@export var display_name : String

var reservations : Array = []

func _ready():
	ShipManager.register_landing(self)
