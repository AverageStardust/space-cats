extends Resource
class_name InventoryVolume

signal slots_changed()
signal focused_changed(index: int)

@export var slots: Array[InventorySlot] = []: set = set_slots
@export var capacity: int: set = set_capacity
@export var focused_index: int = -1: set = set_focused_index

func _init(_capacity = 0):
	if _capacity != 0:
		capacity = _capacity

func set_slots(value):
	slots = value
	for i in slots.size():
		slots[i].focus_changed.connect(slot_focus_changed.bind(i))
		slots[i].changed.connect(emit_slots_changed)
	
	emit_slots_changed()

func set_focused_index(value: int):
	if value == focused_index: return
	if value == -1:
		slots[focused_index].focused = false
	else:
		slots[value].focused = true
	focused_index = value
	focused_changed.emit()

func slot_focus_changed(index: int):
	if slots[index].focused:
		focused_index = index
	elif index == focused_index:
		focused_index = -1

func set_capacity(value):
	var old_capacity = capacity
	capacity = value
	
	if capacity > slots.size():
		for i in capacity - slots.size():
			var slot = InventorySlot.new()
			slot.focus_changed.connect(slot_focus_changed.bind(old_capacity + i))
			slot.changed.connect(emit_slots_changed)
			slots.append(slot)
	else:
		for i in slots.size() - capacity:
			var slot: InventorySlot = slots.pop_back()
			slot.focus_changed.disconnect(slot_focus_changed)
			slot.changed.disconnect(emit_slots_changed)
	
	emit_slots_changed()
	emit_changed()

func contains_item(item_id: String):
	for slot in slots:
		if slot.item_id == item_id:
			return true
	
	return false

func get_tag_slots(tag: InventoryItem.ItemTag):
	var tagged_slots = []
	for slot in slots:
		if slot.has_tag(tag):
			tagged_slots.append(slot)
	
	return tagged_slots

func get_meal_slots():
	var meal_slots = []
	for slot in slots:
		if slot.meal_value > 0:
			meal_slots.append(slot)
	
	return meal_slots

func emit_slots_changed():
	slots_changed.emit()

func can_transfer(slot):
	return transferable_amount(slot) >= slot.amount

func removeable_amount(remove_item_id: String):
	var removeable_amount = 0
	for target_slot in slots:
		removeable_amount += target_slot.removeable_amount(remove_item_id)
	
	return removeable_amount

func transferable_amount(slot: InventorySlot):
	var transfer_amount = 0
	for target_slot in slots:
		transfer_amount += target_slot.transferable_amount(slot)
	
	return min(transfer_amount, slot.amount)

func remove(remove_amount: int, remove_item_id := ""):
	if removeable_amount(remove_item_id) < remove_amount: 
		return false
	
	for slot in slots:
		var slot_remove_amount = min(slot.amount, remove_amount)
		if slot.remove(slot_remove_amount, remove_item_id):
			remove_amount -= slot_remove_amount
	
	return true

func transfer(slot: InventorySlot, max_amount := GlobalManager.MAX_INT):
	for target_slot in slots:
		if target_slot.item_id == slot.item_id:
			max_amount -= target_slot.transfer(slot, max_amount)
		
	for target_slot in slots:
		max_amount -= target_slot.transfer(slot, max_amount)
	
	return slot.is_empty()

func empty():
	for slot in slots:
		slot.empty()

func get_focused() -> InventorySlot:
	if focused_index == -1:
		return null
	return slots[focused_index]
