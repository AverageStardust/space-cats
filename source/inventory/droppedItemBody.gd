extends Node2D
class_name DroppedItemBody

signal collected

@onready var item_display: ItemDisplay = $ItemDisplay
@onready var world = SceneManager.get_current_scene("world")
@onready var player = world.player

var item: DroppedItem
var is_collected := false
var velocity := 0.0
var bob_time := randf()

func _ready():
	item_display.slot = InventorySlot.new(1, item.slot.item_id)
	global_position = item.position

func _process(delta):
	bob_time += delta
	item.idle_time -= delta
	if not is_collected:
		item_display.position.y = sin(bob_time * 3.0) * 3.0 - 8.0

func _physics_process(_delta):
	var target = player.global_position
	var target_up = Vector2.from_angle(player.global_rotation - TAU * 0.25)
	target += target_up * (180.0 if is_collected else 12.0)
	var direction = target - global_position
	
	if is_collected:
		velocity += 0.18
		position += direction.normalized() * velocity
		if direction.length() < 32:
			queue_free()
	else:
		if direction.length() < 32 and item.idle_time <= 0:
			var transfer_amount = player.player.volume.transferable_amount(item.slot)
			if transfer_amount >= item.slot.amount:
				collect()
			elif transfer_amount > 0:
				var slot = InventorySlot.new()
				slot.transfer(item.slot, transfer_amount)
				var item_body = world.add_item(DroppedItem.new(slot, item.position))
				item_body.bob_time = bob_time
				item_body.collect()
	
	global_rotation = player.global_rotation
	item.position = global_position

func collect():
	player.player.volume.transfer(item.slot)
	player.pickup_sound.play()
	is_collected = true
	collected.emit()
