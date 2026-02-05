extends Resource
class_name DroppedItem

@export var slot: InventorySlot
@export var position: Vector2
@export var idle_time: float

func _init(_slot: InventorySlot = InventorySlot.new(), _position: Vector2 = Vector2.ZERO, _idle_time = 1.5):
	slot = _slot
	position = _position
	idle_time = _idle_time
