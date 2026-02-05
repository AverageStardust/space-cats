extends Resource
class_name InventorySlot

signal focus_changed(focused: bool)

@export var item_id: String
@export var amount: int
@export var capacity: int
@export var remaining_durability: int
@export var focused: bool = false: set = set_focused

var item_name: String: get = get_item_name
var max_durability: int: get = get_max_durability
var durability: float: get = get_durability
var meal_value: int: get = get_meal_value

@warning_ignore("shadowed_variable")
func _init(amount := 0, item_id := "", capacity := GlobalManager.MAX_INT):
	self.amount = amount
	self.item_id = item_id
	self.capacity = capacity
	remaining_durability = get_max_durability()

func _to_string():
	if is_empty():
		return "[Empty Slot]"
	else:
		return "[%s %s]" % [amount, item_id]

func get_item_name() -> String:
	if is_empty(): return "[Empty Slot]"
	return ResourceManager.get_item(item_id).name

func get_durability() -> float:
	if max_durability == 0:
		return 1.0
	else:
		return float(remaining_durability) / float(max_durability)

func get_max_durability():
	if item_id == "": return 0
	return ResourceManager.get_item(item_id).max_durability

func get_capacity_with_item(_item_id = item_id) -> int:
	if _item_id == "": return capacity
	var item = ResourceManager.get_item(_item_id)
	if item.max_durability > 0: return 1
	return max(capacity, item.stack_size)

func get_meal_value():
	if is_empty(): return 0
	return ResourceManager.get_item(item_id).meal_value

func has_tag(tag: InventoryItem.ItemTag):
	if is_empty(): return false
	return ResourceManager.get_item(item_id).tags.has(tag)

func set_focused(value):
	if focused == value: return
	focused = value
	focus_changed.emit()
	emit_changed()

func is_broken():
	return remaining_durability <= 0 and max_durability > 0

func damage(damage_amount = 1):
	remaining_durability = max(0, remaining_durability - damage_amount)
	if remaining_durability == 0:
		set_amount_item(amount - 1, item_id, get_max_durability())
	emit_changed()

func is_empty():
	return amount == 0

func empty():
	set_amount_item(0)

@warning_ignore("shadowed_variable")
func set_amount_item(amount: int, item_id := self.item_id, remaining_durability := 0):
	self.amount = amount
	
	if self.amount == 0: 
		self.item_id = ""
		self.remaining_durability = 0
	else:
		self.item_id = item_id
		if remaining_durability == 0 and max_durability > 0:
			self.remaining_durability = max_durability
		else:
			self.remaining_durability = remaining_durability
	emit_changed()

func move(slot: InventorySlot):
	if item_id == slot.item_id:
		transfer(slot)
	else:
		swap(slot)

func can_transfer(slot: InventorySlot):
	return transferable_amount(slot) >= slot.amount

func removeable_amount(remove_item_id: String):
	if remove_item_id != "" and remove_item_id != item_id:
		return 0
	else:
		return self.amount

func transferable_amount(slot: InventorySlot):
	if item_id == "":
		return min(get_capacity_with_item(slot.item_id), slot.amount)
	if slot.item_id == item_id:
		return min(get_capacity_with_item() - amount, slot.amount)
	return 0

func remove(remove_amount: int, remove_item_id := ""):
	if remove_item_id != "" and remove_item_id != item_id:
		return false
	else:
		if amount < remove_amount: return false
		set_amount_item(amount - remove_amount)
		return true

func transfer(slot: InventorySlot, max_amount := GlobalManager.MAX_INT):
	var transfer_amount = min(transferable_amount(slot), max_amount)
	if transfer_amount > 0:
		set_amount_item(amount + transfer_amount, slot.item_id, slot.remaining_durability)
		slot.set_amount_item(slot.amount - transfer_amount)
	return transfer_amount

func swap(slot: InventorySlot):
	if slot.get_capacity_with_item(item_id) < amount:
		return false
	if get_capacity_with_item(slot.item_id) < slot.amount:
		return false
	
	var temp_item_id = item_id
	var temp_amount = amount
	var temp_remaining_durability = remaining_durability
	set_amount_item(slot.amount, slot.item_id, slot.remaining_durability)
	slot.set_amount_item(temp_amount, temp_item_id, temp_remaining_durability)
	
	return true
