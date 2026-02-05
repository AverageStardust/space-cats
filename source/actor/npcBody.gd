extends ActorBody

@onready var dialogue_box: DialogueBox = $DialogueBox

@export var spawn_angle = 0.0

var dialogue: Dialogue

func _ready():
	var parent: CelestialBody = get_parent()
	surface = parent
	position = Vector2.from_angle(spawn_angle - TAU * 0.25) * parent.celestial.radius
	dialogue_box.dialogue_changed.connect(on_dialogue_changed)

func get_standing_direction():
	var true_direction = super.get_standing_direction()
	if abs(angle_difference(world.player.global_rotation, true_direction)) < 0.25:
		return world.player.global_rotation
	return true_direction

func on_dialogue_changed(value):
	if value != null:
		dialogue = value
		world.player.target_point = $TalkPoint
		dialogue.kiss.connect(kiss_player)
	else:
		dialogue.kiss.disconnect(kiss_player)
		dialogue = value
		world.player.target_point = null

func kiss_player():
	world.player.target_point = $KissPoint
	await world.player.reached_point
	await get_tree().create_timer(0.2).timeout
	$HeartParticles.emitting = true
	await get_tree().create_timer(0.5).timeout
	await world.player.camera.fade_out()
	SceneManager.open_previous_scene()
