extends Node

const SCENE_PATH = "res://source/scene/%s.tscn"

@onready var root = get_tree().root
@onready var current_scene: Node = get_node("/root/Loading")
@onready var current_packed_scene: PackedScene
@onready var previous_packed_scenes: Array[PackedScene] = []

var packed_scenes = Dictionary()
var instantiating = false

func _ready():
	get_tree().auto_accept_quit = false
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_and_quit()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if not SceneManager.open_previous_scene():
			SceneManager.save_and_quit()

func save_and_quit():
	var _currect_scene = access_currect_scene()
	_currect_scene.queue_free()
	await _currect_scene.tree_exited
	get_tree().quit()

func get_current_scene(scene_name) -> Node:
	if not packed_scenes.has(scene_name):
		return null
	if packed_scenes[scene_name] != current_packed_scene:
		return null
	return access_currect_scene()

func open_scene(packed_scene):
	if typeof(packed_scene) == TYPE_STRING:
		packed_scene = load_packed_scene(packed_scene)
	
	previous_packed_scenes.append(current_packed_scene)
	current_packed_scene = packed_scene
	current_scene.queue_free()
	
	instantiating = true
	current_scene = packed_scene.instantiate()
	instantiating = false
	
	root.add_child(current_scene)

func access_currect_scene():
	if instantiating:
		push_error("Tried to access new scene while instantiating")
		return null
	
	return current_scene

func open_previous_scene():
	var packed_scene = previous_packed_scenes.pop_back()
	if packed_scene == null:
		return false
	open_scene(packed_scene)
	previous_packed_scenes.pop_back()
	return true

func load_packed_scene(scene_name: String):
	if not packed_scenes.has(scene_name):
		packed_scenes[scene_name] = load(SCENE_PATH % scene_name)
	
	return packed_scenes[scene_name]
