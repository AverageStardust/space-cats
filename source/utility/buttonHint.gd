extends Sprite2D
class_name ButtonHint

const ERROR_UV = Vector2(192, 0)
const MOUSE_UV = Vector2(0, 272)

@onready var world: World = SceneManager.get_current_scene("world")

@export var action: StringName: set = set_action
@export var progress := 0.0: set = set_progress

func _ready():
	material = material.duplicate()
	InputManager.input_source_changed.connect(update_icon)
	update_icon()

func _physics_process(_delta):
	var target_scale = 1.00 / world.player.camera.zoom.x
	
	if abs(scale.x - target_scale) > 0.01:
		scale = lerp(scale, Vector2(target_scale, target_scale), 0.12)
	elif scale.x != target_scale:
		scale = Vector2(target_scale, target_scale)

func pop():
	scale = Vector2(2, 2)

func set_action(value):
	action = value
	update_icon()

func set_click_icon():
	region_rect.position = MOUSE_UV
	visible = true

func set_progress(value: float):
	if value == progress: return
	progress = value
	if progress <= 0.0:
		material.set_shader_parameter("progress_pixel", -8)
	else:	
		material.set_shader_parameter("progress_pixel", progress * 15 - 7)

func update_icon():
	if action == "":
		visible = false
		return
	
	var uv = InputManager.action_to_icon_uv(action)
	region_rect.position = ERROR_UV if uv == null else uv
	visible = true
