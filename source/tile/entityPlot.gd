extends Node2D
class_name EntityPlot

@onready var world = SceneManager.get_current_scene("world")
@onready var interaction_panel = $InteractionPanel
@onready var texture_rect = $TextureRect

@export var celestial_tile: CelestialTile

var tile: Tile: set = set_tile

func _ready():
	InputManager.holder_changed.connect(update_enabled)
	world.save_changed.connect(on_save_changed)

func on_save_changed(save):
	save.player.volume.focused_changed.connect(update_enabled)
	save.player.volume.slots_changed.connect(update_enabled)

func set_tile(value: Tile):
	if tile: 
		tile.entity_changed.disconnect(update_enabled)
	tile = value
	tile.entity_changed.connect(update_enabled)
	update_enabled()

func _on_interaction_panel_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			on_interacted()

func update_enabled():
	if not world.is_node_ready(): await world.ready
	
	texture_rect.visible = false
	interaction_panel.visible = false
	
	var tile_item = get_tile_item()
	
	# can be broken
	if tile_item != "":
		interaction_panel.visible = true
	
	# can be placed
	if tile.entity_id == "" or tile_item != "":
		if get_holder_entity() != "":
			texture_rect.visible = true
			interaction_panel.visible = true
	
	var shape = Control.CURSOR_POINTING_HAND if interaction_panel.visible else Control.CURSOR_ARROW
	interaction_panel.mouse_default_cursor_shape = shape

func on_interacted():
	var item := get_tile_item()
	var entity := get_holder_entity()

	tile.entity_id = entity
	
	if entity != "":
		use_holder_item()

	if item != "":
		world.player.take_slot(InventorySlot.new(1, item))

func get_tile_item() -> String:
	if tile.entity_id == "": return ""
	return ResourceManager.get_entity(tile.entity_id).item

func get_holder_entity() -> String:
	if not InputManager.has_item_holder(): return ""
	var slot = InputManager.get_item_holder().slot
	if slot.item_id == "": return ""
	var item = ResourceManager.get_item(slot.item_id)
	return item.entity

func use_holder_item():
	var slot = InputManager.get_item_holder().slot
	assert(slot.remove(1))
