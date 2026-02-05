extends Node2D

@onready var near_sprite: Sprite2D = $NearSprite
@onready var far_sprite: Sprite2D = $FarSprite

func _process(_delta):
	animate_sprite(near_sprite, 0.4, Vector2(67, 175))
	animate_sprite(far_sprite, 0.15, Vector2(203, 85))

func animate_sprite(sprite, ratio, offset):
	var sprite_position = (global_position / 256).round() * 256
	sprite.region_rect.position = (global_position * -ratio) + offset
	sprite.global_position = sprite_position
	sprite.global_rotation = 0
