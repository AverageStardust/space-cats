extends Node

const save_path = "user://saveGame%s.tres"
const initial_path = "res://resources/initalGame.tres"
const autosave_interval := 30.0

var state: SaveGame: set = set_state
var autosave_timeout := 0.0

func _ready():
	if autosave_timeout <= 0.0:
		save()
		autosave_timeout += autosave_interval

func load_or_init(id = 0):
	if ResourceLoader.exists(save_path % [id]):
		state = load(save_path % [id])
	else:
		load_init()

func load_init():
	if ResourceLoader.exists(initial_path):
		state = load(initial_path)
	else:
		state = SaveGame.new()

func delete(id = 0):
	DirAccess.remove_absolute(save_path % [id])

func save(id = 0):
	if state == null: return
	ResourceSaver.save(state, save_path % [id], 4)

func save_init():
	if state == null: return
	var init_state = state.duplicate()
	init_state.make_unplayed()
	ResourceSaver.save(init_state, initial_path)

func set_state(value):
	state = value
	save()
