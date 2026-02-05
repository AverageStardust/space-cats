extends Control
class_name ItemHolder

const MOUSE_OFFSET = Vector2(-9, 2)

@onready var player = SceneManager.get_current_scene("world").player
@onready var item_display = $ItemDisplay

var slot := InventorySlot.new()

func _ready():
	position = get_global_mouse_position() + MOUSE_OFFSET
	item_display.slot = slot
	slot.changed.connect(on_slot_changed)
	item_display.tooltips = false

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		position = event.position + MOUSE_OFFSET

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				player.drop_slot(slot.duplicate())
				slot.empty()
			else:
				var drop_slot = InventorySlot.new()
				drop_slot.transfer(slot, 1)
				player.drop_slot(drop_slot)
				
func _exit_tree():
	player.take_slot(slot)

func on_slot_changed():
	if slot.is_empty():
		queue_free()
