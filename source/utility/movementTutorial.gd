extends Node2D

const FADE_OUT_SPEED: float = 2.0
const COMPLETE_THRESHOLD: float = 0.5

@onready var left_hint = $LeftHint
@onready var right_hint = $RightHint

var player: Player: set = set_player
var left_time: float = 0
var right_time: float = 0

func set_player(value):
	player = value
	if player.tutorials_done.move_left:
		left_hint.visible = false
	if player.tutorials_done.move_right:
		right_hint.visible = false

func _process(delta):
	if Input.is_action_pressed("move_left"):
		left_time += delta
	if Input.is_action_pressed("move_right"):
		right_time += delta
	
	left_hint.set_progress(left_time / COMPLETE_THRESHOLD)
	right_hint.set_progress(right_time / COMPLETE_THRESHOLD)
	
	if player == null: return
	
	if left_time > COMPLETE_THRESHOLD:
		player.tutorials_done.move_left = true
	if right_time > COMPLETE_THRESHOLD:
		player.tutorials_done.move_right = true
	
	if player.tutorials_done.move_left:
		left_hint.modulate.a -= delta * FADE_OUT_SPEED
	if player.tutorials_done.move_right:
		right_hint.modulate.a -= delta * FADE_OUT_SPEED
