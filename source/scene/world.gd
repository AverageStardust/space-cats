extends Node2D
class_name World

signal save_changed(save: SaveGame)

var RAFT_BODY_SCENE = ResourceManager.get_packed_scene("actor/raftBody.tscn")
var DROPPED_ITEM_BODY_SCENE = ResourceManager.get_packed_scene("inventory/droppedItemBody.tscn")

@onready var console = $ConsoleWindow/Console
@onready var player = $Player
@onready var ship = $Ship
@onready var interface = $Interface
@onready var hotbar_panel = $Interface/HotbarPanel
@onready var hotbar = $Interface/HotbarPanel/Hotbar
@onready var chest_panel = $Interface/ChestPanel
@onready var chest = $Interface/ChestPanel/Chest
@onready var crafting_panel = $Interface/CraftingPanel
@onready var crafting = $Interface/CraftingPanel/Crafting
@onready var recipe_panel = $Interface/RecipePanel
@onready var recipe_button = $Interface/RecipeButton
@onready var fisning_panel = $Interface/FishingPanel
@onready var fishing = $Interface/FishingPanel/FishingInterface
@onready var radar_panel = $Interface/RadarPanel
@onready var dialogue_panel = $Interface/DialoguePanel
@onready var dialogue = $Interface/DialoguePanel/DialogueInterface
@onready var home = $Home
@onready var sun = $DirectionalLight2D

var save: SaveGame: set = set_save

func _ready():
	set_save(SaveManager.state)

func _process(delta):
	sun.rotation += delta * 0.04
	save.sun_angle = sun.rotation

func _exit_tree():
	SaveManager.save()

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("console_toggle"):
			console.toggle()

func _on_recipe_button_pressed():
	recipe_panel.visible = not recipe_panel.visible

func set_save(value):
	if save != null:
		hotbar.volume.slots_changed.disconnect(on_hotbar_slots_changed)
	save = value
	
	if save.player == null:
		save.player = player.player
	else:
		player.player = save.player
	
	hotbar.volume = save.player.volume
	hotbar.volume.slots_changed.connect(on_hotbar_slots_changed)
	
	if save.ship == null:
		save.ship = ship.ship
	else:
		ship.ship = save.ship
	
	if save.home == null:
		save.home = home.celestial
	else:
		home.celestial = save.home
	
	if save.raft != null:
		var raft = RAFT_BODY_SCENE.instantiate()
		raft.actor = save.raft
		add_child(raft)
	
	for item in save.items:
		instance_item(item)
	
	console.previous_lines = save.console_previous_lines
	sun.rotation = save.sun_angle
	save.played = true
	
	save_changed.emit(save)

func on_hotbar_slots_changed():
	for slot in hotbar.volume.slots:
		if slot.item_id == "": continue
		save.discover(&"item", slot.item_id)
		var item = ResourceManager.get_item(slot.item_id)
		for tag in item.tags:
			save.discover(&"item_tag", tag)

func add_item(item: DroppedItem):
	if item.slot.is_empty(): return
	
	save.items.push_back(item)
	return instance_item(item)

func instance_item(item: DroppedItem):
	var item_body = DROPPED_ITEM_BODY_SCENE.instantiate()
	
	item_body.item = item
	item_body.collected.connect(remove_item.bind(item))
	
	add_child(item_body)
	return item_body

func remove_item(item: DroppedItem):
	save.items.erase(item)
