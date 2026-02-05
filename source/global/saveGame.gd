extends Resource
class_name SaveGame

signal discovered(type: String, id: String)

@export var home: Celestial = null
@export var player: Player = null
@export var ship: Ship = null
@export var raft: Actor = null
@export var items: Array[DroppedItem] = []
@export var console_previous_lines: Array[String] = []
@export var interaction_counts := {}
@export var discoveries := {}
@export var dialogue_states := {}
@export var hints_points := 0
@export var fish_caught := 0
@export var sun_angle := 0.0
@export var played := false

func make_unplayed():
	items = []
	console_previous_lines = []
	interaction_counts = {}
	discoveries = {}
	dialogue_states = {}
	played = false
	
	player.reset()
	ship.reset()
	home.reset_position()
	discover_starting()

func discover_starting():
	discover(&"recipe", "assembly/campfire")
	discover(&"recipe", "assembly/chest")
	discover(&"recipe", "assembly/stonePickaxe")
	discover(&"recipe", "assembly/woodPickaxe")
	
	discover(&"recipe", "campfire/cannedAnchovy")
	discover(&"recipe", "campfire/fruitJam")
	discover(&"recipe", "campfire/fruitTart")
	discover(&"recipe", "campfire/gardenSalad")
	discover(&"recipe", "campfire/herbBread")

func get_discovery_by_type(type: StringName) -> Dictionary:
	if not discoveries.has(type): return {}
	return discoveries[type]

func is_discovered(type: StringName, id):
	if not discoveries.has(type): return false
	return discoveries[type].has(id)

func discover(type: StringName, id):
	if is_discovered(type, id): return
	
	if not discoveries.has(type):
		discoveries[type] = {}
	if not discoveries[type].has(id):
		discoveries[type][id] = 1
		discovered.emit(type, id)
	else:
		discoveries[type][id] += 1

func get_interaction_count(interaction: String):
	return interaction_counts.get(interaction, 0)

func increment_interaction(interaction: String):
	if not interaction_counts.has(interaction):
		interaction_counts[interaction] = 1
	else:
		interaction_counts[interaction] += 1
