extends MeshInstance3D

var noise : FastNoiseLite = FastNoiseLite.new()

var sample_position : float = 0

func _process(delta: float) -> void:
	sample_position = sample_position + delta * 600
	scale = Vector3.ONE * (0.6 * noise.get_noise_1d(sample_position) + 1.5)
