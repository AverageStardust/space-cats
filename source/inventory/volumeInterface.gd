extends GridContainer
class_name VolumeInterface

var SLOT_SCENE = ResourceManager.get_packed_scene("inventory/slotInterface.tscn")
const MAX_WIDTH: int = 12

@onready var empty_sound: AudioStreamPlayer = $EmptySound
@onready var fill_sound: AudioStreamPlayer = $FillSound
@onready var transfer_sound: AudioStreamPlayer = $TransferSound

@export var volume: InventoryVolume: set = set_volume
@export var top_volume_interface: VolumeInterface = null
@export var bottom_volume_interface: VolumeInterface = null
@export var is_hotbar := false
@export var allow_fill := true
@export var allow_empty := true

var slot_interfaces: Array[SlotInterface] = []

func set_volume(value):
	if volume: volume.disconnect("changed", update_volume)
	volume = value
	volume.connect("changed", update_volume)
	update_volume()

func update_volume():
	if not is_node_ready(): await ready
	
	for slot_interface in slot_interfaces:
		slot_interface.queue_free()
	
	slot_interfaces = []
	
	for i in volume.capacity:
		var slot_interface = SLOT_SCENE.instantiate()
		slot_interface.is_hotbar = is_hotbar
		slot_interface.slot = volume.slots[i]
		slot_interface.empty_slot.connect(on_empty_slot)
		slot_interface.fill_slot.connect(on_fill_slot)
		slot_interfaces.append(slot_interface)
		add_child(slot_interface)

func _exit_tree():
	if not is_hotbar:
		move_focus_away()
	
func move_focus_away():
	if volume.focused_index == -1: return
	var coord_x = get_volume_focused_coord().x
	
	if top_volume_interface != null and top_volume_interface.is_hotbar:
		top_volume_interface.focus_bottom(coord_x)
	elif bottom_volume_interface != null and bottom_volume_interface.is_hotbar:
		bottom_volume_interface.focus_top(coord_x)
	volume.set_focused_index(-1)

func _unhandled_input(event):
	if is_hotbar:
		for i in min(MAX_WIDTH, volume.capacity):
			if event.is_action_pressed("slot_%s" % [i]):
				volume.set_focused_index(i)
				return
	
	if volume.focused_index == -1: return
	if InputManager.input_source == "keyboard": return
	
	var focused_coord = get_volume_focused_coord()
	var volume_size = volume_size_at_coord(focused_coord)
	if event.is_action_pressed("ui_up"):
		if focused_coord.y > 0:
			focused_coord.y -= 1
			volume.set_focused_index(focus_coord_to_index(focused_coord))
		elif top_volume_interface != null:
			top_volume_interface.focus_bottom(focused_coord.x)
	
	elif event.is_action_pressed("ui_down"):
		if focused_coord.y < volume_size.y - 1:
			focused_coord.y += 1
			volume.set_focused_index(focus_coord_to_index(focused_coord))
		elif bottom_volume_interface != null:
			bottom_volume_interface.focus_top(focused_coord.x)
	
	elif event.is_action_pressed("ui_left") or (is_hotbar and event.is_action_pressed("scroll_up")):
		focused_coord.x = posmod(focused_coord.x - 1, volume_size.x)
		volume.set_focused_index(focus_coord_to_index(focused_coord))
	
	elif event.is_action_pressed("ui_right") or (is_hotbar and event.is_action_pressed("scroll_down")):
		focused_coord.x = posmod(focused_coord.x + 1, volume_size.x)
		volume.set_focused_index(focus_coord_to_index(focused_coord))

func get_volume_focused_coord():
	@warning_ignore("integer_division")
	return Vector2i(volume.focused_index % MAX_WIDTH, volume.focused_index / MAX_WIDTH)

func volume_size_at_coord(coord: Vector2i):
	var width = max(0, volume.capacity - coord.y * MAX_WIDTH)
	@warning_ignore("integer_division")
	var height = (volume.capacity + MAX_WIDTH - 1 - coord.x) / MAX_WIDTH
	return Vector2i(width, height)

func focus_coord_to_index(coord: Vector2i) -> int:
	return coord.x + coord.y * MAX_WIDTH

func focus_top(x_coord: int):
	if InputManager.input_source == "keyboard" and not is_hotbar: return
	volume.set_focused_index(min(volume.capacity - 1, x_coord))

func focus_bottom(x_coord: int):
	if InputManager.input_source == "keyboard" and not is_hotbar: return
	
	if volume.capacity <= MAX_WIDTH:
		focus_top(x_coord)
	else:
		var y_coord = volume_size_at_coord(Vector2i(x_coord, 0)).y - 1
		volume.set_focused_index(focus_coord_to_index(Vector2i(x_coord, y_coord)))

func on_empty_slot(slot: InventorySlot, max_amount: int):
	if not allow_empty: return
	if slot.is_empty(): return
	
	if top_volume_interface != null:
		top_volume_interface.volume.transfer(slot, max_amount)
		transfer_sound.play()
	elif bottom_volume_interface != null:
		bottom_volume_interface.volume.transfer(slot, max_amount)
		transfer_sound.play()
	else:
		var holder = InputManager.get_item_holder()
		holder.slot.transfer(slot, max_amount)
		empty_sound.play()

func on_fill_slot(slot: InventorySlot):
	if not allow_fill: return
	var holder = InputManager.get_item_holder()
	slot.move(holder.slot)
	fill_sound.play()
