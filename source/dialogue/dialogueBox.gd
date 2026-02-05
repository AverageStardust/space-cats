extends Control
class_name DialogueBox

signal dialogue_changed(dialogue: Dialogue)

@onready var world: World = SceneManager.get_current_scene("world")
@onready var interaction_box = $InteractionBox

@export var dialogue_id: String
@export var dialogue_path := "start"

var dialogue: Dialogue = null: set = set_dialogue

func _ready():
	interaction_box.interacted.connect(on_interacted)
	world.ready.connect(on_world_ready)

func _exit_tree():
	close_dialogue()

func on_world_ready():
	world.player.focus_unlocked.connect(close_dialogue)

func on_interacted():
	if dialogue == null:
		dialogue = DialogueManager.open_dialogue(dialogue_id, dialogue_path)
		dialogue.closed.connect(on_closed)
		world.player.lock_focus({ interaction_box.action: interaction_box})
	else:
		world.dialogue._on_continue_button_pressed()

func set_dialogue(value):
	dialogue = value
	dialogue_changed.emit(dialogue)

func close_dialogue():
	if dialogue != null:
		dialogue.close(true)

func on_closed():
	world.player.unlock_focus()
	dialogue.closed.disconnect(on_closed)
	dialogue = null
