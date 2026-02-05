extends Node

const DEV: bool = false
const MAX_INT = 2 ** 63 - 1

@onready var window = get_tree().get_root()

var images = [
	preload("res://assets/cursor/arrow.png"),
	preload("res://assets/cursor/ibeam.png"),
	preload("res://assets/cursor/pointing.png"),
	preload("res://assets/cursor/cross.png"),
	preload("res://assets/cursor/wait.png"),
	preload("res://assets/cursor/wait.png"),
	preload("res://assets/cursor/grab.png"),
	preload("res://assets/cursor/drop.png"),
	preload("res://assets/cursor/forbidden.png")]

var hotspots = [
	Vector2.ZERO,
	Vector2(5, 5),
	Vector2(3, 0),
	Vector2(4, 4),
	Vector2(4, 4),
	Vector2(4, 4),
	Vector2(3, 0),
	Vector2(5, 5),
	Vector2(5, 5)
]

var background_angle := randf_range(0, TAU)
var old_stretch := 0
var licence_text := ""

func _ready():
	for i in images.size():
		images[i] = images[i].get_image()

func _process(_delta):
	var stretch_vec = window.size / window.content_scale_size
	var stretch: int = clamp(min(stretch_vec.x, stretch_vec.y), 1, 12)
	if stretch == old_stretch: return
	
	for i in images.size():
		images[i].resize(stretch * 10, stretch * 10, Image.INTERPOLATE_NEAREST)
		var image_texture = ImageTexture.create_from_image(images[i])
		Input.set_custom_mouse_cursor(image_texture, i, hotspots[i] * stretch)
	
	old_stretch = stretch
