extends EntityScene

const EXTRA_STENGTH_BONUS_MULTIPLIER = 0.75
const ASH_BONUS_TIME = 20.0
const ASH_ITEM_ID = "ash"

@onready var world = SceneManager.get_current_scene("world")
@onready var player: PlayerBody = world.player
@onready var hotbar_volume: InventoryVolume = world.hotbar.volume
@onready var interaction_box: InteractionBox = $InteractionBox
@onready var particles = $CPUParticles2D
@onready var sounds = {
	CollectableOptions.BreakSound.rock: $RockSound,
	CollectableOptions.BreakSound.rustle: $RustleSound,
	CollectableOptions.BreakSound.wood: $WoodSound
}

var options: CollectableOptions
var state: CollectableState

func _ready():
	hotbar_volume.focused_changed.connect(update_interaction)
	hotbar_volume.slots_changed.connect(update_interaction)
	interaction_box.interacted.connect(on_interacted)
	state.changed.connect(state_changed)
	state_changed()
	update_interaction()

func _process(delta):
	state.broken_time = max(0, state.broken_time - delta)
	if interaction_box.press_time > 0.01:
		var sound = sounds[options.sound]
		if not sound.playing:
			sound.play_random()

func update_interaction():
	interaction_box.enabled = not state.broken
	if options.custom_interaction != "":
		interaction_box.interaction = "harvest_" + options.custom_interaction
	else:
		interaction_box.interaction = "harvest_collectable"
	
	if state.broken:
		if options.fertilizable and hotbar_volume.get_focused().item_id == ASH_ITEM_ID:
			interaction_box.enabled = true
			interaction_box.interaction = "apply_ash"
			interaction_box.interaction_time = 0
		return
	
	var break_time := options.break_time
	var break_strength := -options.break_stength
	var tool := get_hotbar_tool()
	
	if tool != null and tool.tool_type == options.tool_type:
		break_strength += tool.tool_strength
		if tool.tool_specialty == celestial_tile.tile.entity_id:
			break_strength += 2
	
	if break_strength < 0:
		interaction_box.enabled = false
		return
	
	break_time *= pow(EXTRA_STENGTH_BONUS_MULTIPLIER, break_strength)
	
	interaction_box.interaction_time = break_time

func state_changed():
	var offset = options.broken_texture_offset if state.broken else options.texture_offset
	changed_texture_offset.emit(offset)
	update_interaction()

func on_interacted():
	if state.broken:
		use_ash()
	else:
		break_collectable()

func use_ash():
	state.broken_time = max(0, state.broken_time - ASH_BONUS_TIME)
	particles.emitting = true
	
	var slot = hotbar_volume.get_focused()
	assert(slot.remove(1, ASH_ITEM_ID))

func break_collectable():
	state.broken_time = options.regrow_time
	
	var tool = get_hotbar_tool()
	if tool != null:
		hotbar_volume.get_focused().damage()
		
	for drop in options.drops:
		player.take_slot(InventorySlot.new(1, drop))

func get_hotbar_tool() -> InventoryItem:
	if options.tool_type == InventoryItem.ToolType.None:
		return null
	
	var slot = hotbar_volume.get_focused()
	if slot == null or slot.item_id == "": 
		return null
	
	var item = ResourceManager.get_item(slot.item_id)
	if item.tool_type != options.tool_type: 
		return null
	
	return item
