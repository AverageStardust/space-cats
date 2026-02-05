extends PanelContainer

var noise := FastNoiseLite.new()
var intial_position: Vector2
var time: float = 0
var shake_speed: float
var shake_strength: float

func _process(delta):
	shake_strength = max(0, shake_strength - delta * 25.0)
	if shake_strength > 0:
		time += delta * shake_speed
		var offset = Vector2(noise.get_noise_2d(234.0, time), 0.0)
		position = intial_position + offset * shake_strength

func shake(_stength: float, _speed: float = 800.0):
	if shake_strength <= 0:
		intial_position = position
	time = 0
	shake_strength = _stength
	shake_speed = _speed
