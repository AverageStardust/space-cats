extends Area2D
class_name InteractionBox

signal interacted
signal clicked

const FADE_IN_SPEED = 3.0
const FADE_OUT_SPEED = 1.8
const PRESS_LOSS_RATE = 4.0

@onready var world: World = SceneManager.get_current_scene("world")
@onready var button_hint: ButtonHint = $ButtonHint
@onready var panel = $Panel

@export var action: StringName = "interact_1"
@export var interaction: StringName: set = set_interaction
@export var interaction_time: float = 0
@export var enabled := true: set = set_enabled

var dismissed := false
var in_range := false
var focused := false: set = set_focused
var pressed := false
var press_time := 0.0

func _ready():
	button_hint.action = action
	button_hint.modulate.a = 0.0
	InputManager.interaction_dismissed.connect(update_dismissed)

func set_interaction(value):
	interaction = value
	update_dismissed()

func _process(delta):
	if not enabled or not focused or dismissed and not pressed:
		if button_hint.modulate.a > 0.0:
			button_hint.modulate.a = max(0.0, button_hint.modulate.a - delta * FADE_OUT_SPEED)
	else:
		if button_hint.modulate.a < 1.0:
			button_hint.modulate.a = min(1.0, button_hint.modulate.a + delta * FADE_IN_SPEED)
	
	if button_hint.modulate.a > 0.0:
		button_hint.global_rotation = world.player.global_rotation
	else:
		return
	
	if pressed:
		if in_range:
			press_time += delta
		else:
			pressed = false
		
	if not pressed and press_time > 0:
		press_time = press_time - delta * PRESS_LOSS_RATE
		if press_time < 0:
			press_time = 0
	
	if interaction_time == 0:
		button_hint.set_progress(1 if pressed else 0)
	else:
		button_hint.set_progress(press_time / interaction_time)
	
	if pressed:
		while press_time >= interaction_time:
			interacted.emit()
			button_hint.pop()
			InputManager.count_interaction(interaction)
			
			if interaction_time <= 0:
				press_time = 0
				button_hint.modulate.a = 1.0
				pressed = false
				break
			else:
				press_time -= interaction_time

func set_enabled(value):
	enabled = value
	if not is_node_ready(): await ready
	
	if not enabled: pressed = false

func set_focused(value):
	if not enabled and value: return
	focused = value
	if not focused:
		pressed = false

func on_source_event(event: InputEvent):
	if event.is_action_pressed(action) and focused and enabled:
		button_hint.update_icon()
		pressed = true
	elif event.is_action_released(action):
		pressed = false

func update_dismissed():
	dismissed = InputManager.is_interaction_dismissed(interaction)

func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
