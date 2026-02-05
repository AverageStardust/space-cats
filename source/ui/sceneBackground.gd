extends Node

@onready var background = $Background

func _process(delta):
	GlobalManager.background_angle += delta * 0.4
	var angle = GlobalManager.background_angle
	background.position.x = cos(angle) * 192 + 320
	background.position.y = sin(angle) * 192 + 180
