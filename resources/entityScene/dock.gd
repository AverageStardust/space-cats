extends EntityScene

var RAFT_BODY_SCENE = ResourceManager.get_packed_scene("actor/raftBody.tscn")
const RAFT_ITEM_ID = "raft"
const PLAYER_SPAWN_INDEX = 0

@onready var world = SceneManager.get_current_scene("world")
@onready var player: PlayerBody = world.player
@onready var fishing: FishingInterface = world.fishing
@onready var hotbar_volume: InventoryVolume = world.hotbar.volume
@onready var interaction_box: InteractionBox = $InteractionBox
@onready var spawn_points = [$SpawnPointPlayer, $SpawnPointLeft, $SpawnPointRight]

var open := false: set = set_open

var options: DockOptions

func _ready():
	player.changed_surface.connect(func(_surface): update_interaction())
	hotbar_volume.focused_changed.connect(update_interaction)
	hotbar_volume.slots_changed.connect(update_interaction)
	interaction_box.interacted.connect(on_interacted)
	update_interaction()

func on_interacted():
	if is_riding_raft():
		var raft = player.surface
		raft.destroy()
		var spawn_point = spawn_points[PLAYER_SPAWN_INDEX]
		player.global_position = spawn_point.global_position
		player.global_rotation = spawn_point.global_rotation
		player.take_slot(InventorySlot.new(1, RAFT_ITEM_ID))
	elif is_holding_raft():
		var raft_body = RAFT_BODY_SCENE.instantiate()
		var spawn_point = spawn_points[options.spawn_index]
		raft_body.global_position = spawn_point.global_position
		raft_body.global_rotation = spawn_point.global_rotation
		world.add_child(raft_body)
		use_hotbar_item()
	else:
		open = not open
		
func set_open(value):
	if open == value: return
	
	open = value
	update_interaction()
	world.fisning_panel.visible = open
	
	if open:
		SoundManager.play_sound("open")
		player.lock_focus({ interaction_box.action: interaction_box})
	else:
		SoundManager.play_sound("close")
		player.unlock_focus()

func update_interaction():
	if is_riding_raft() or is_holding_raft():
		interaction_box.enabled = true
		interaction_box.interaction = "place_raft"
	elif is_holding_spear() or open:
		interaction_box.enabled = true
		interaction_box.interaction = "fish"
	else:
		interaction_box.enabled = false

func use_hotbar_item():
	var slot = hotbar_volume.get_focused()
	assert(slot.remove(1, RAFT_ITEM_ID))

func is_holding_raft():
	var slot = hotbar_volume.get_focused()
	return slot != null and slot.item_id == RAFT_ITEM_ID

func is_holding_spear():
	var slot = hotbar_volume.get_focused()
	if slot == null or slot.item_id == "": return false
	
	var item: InventoryItem = ResourceManager.get_item(slot.item_id)
	return item.tool_type == InventoryItem.ToolType.Spear

func is_riding_raft():
	return player.surface is RaftBody
