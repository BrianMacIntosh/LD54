extends AnimationPlayer

@export var track_name : StringName;

func _ready() -> void:
	play(track_name)
