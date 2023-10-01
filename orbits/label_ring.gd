@tool
extends Marker3D

@export var label_text : String : set = set_label_text, get = get_label_text

func set_label_text(value):
	label_text = value
	$Control/Label.text = value

func get_label_text():
	return label_text

func _ready() -> void:
	$Control/Label.text = label_text
