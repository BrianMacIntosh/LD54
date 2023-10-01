extends Control

func _ready() -> void:
	await $Timer.timeout
	queue_free()
