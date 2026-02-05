extends PanelContainer
class_name SlotInterface

signal empty_slot(slot: InventorySlot, max_amount: int)
signal fill_slot(slot: InventorySlot)

@onready var slot_texture = $SlotTexture
@onready var item_display: ItemDisplay = $CenterContainer/ItemDisplay

var slot: InventorySlot: set = set_slot
var is_hotbar = false
var rmb_repeater = Repeater.new()
var rmb_shift_pressed: bool

func _ready():
	slot_texture.texture = slot_texture.texture.duplicate()
	InputManager.slot_interface_focused.connect(on_other_focused)
	rmb_repeater.click.connect(on_rmb_repeater_click)

func _process(delta):
	rmb_repeater.process(delta)

func set_slot(value):
	if not is_node_ready(): await ready
	
	if slot: 
		slot.changed.disconnect(update_slot)
		slot.focus_changed.disconnect(on_focused_changed)
	slot = value
	slot.changed.connect(update_slot)
	slot.focus_changed.connect(on_focused_changed)
	update_slot()
	
	item_display.slot = slot

func on_other_focused(interface):
	if interface == self: return
	slot.focused = false

func on_focused_changed():
	if slot.focused:
		InputManager.emit_slot_focused(self)

func update_slot():
	slot_texture.texture.region.position.x = 32 if slot.focused else 0

func _gui_input(event):
	if not (event is InputEventMouseButton): return
	if not event.is_pressed(): return
	
	if event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if InputManager.has_item_holder():
			fill_slot.emit(slot)
			slot.focused = true
		else:
			empty_slot.emit(slot, GlobalManager.MAX_INT)
		if not InputManager.has_item_holder():
			if InputManager.input_source != "keyboard" or is_hotbar:
				slot.focused = true
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		rmb_shift_pressed = event.shift_pressed
		rmb_repeater.enable()

func _input(event):
	if event is InputEventMouseButton and event.is_released():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rmb_repeater.disable()

func on_rmb_repeater_click():
	if rmb_shift_pressed:
		empty_slot.emit(slot, ceil(slot.amount / 2.0))
	else:
		empty_slot.emit(slot, 1)
