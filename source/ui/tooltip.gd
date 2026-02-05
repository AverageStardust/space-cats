extends PanelContainer
class_name Tooltip

const MOUSE_OFFSET = Vector2(-91, 12)
const MEAL_VALUE_NAMES: Array[String] = ["", "snack", "appetizer", "meal", "feast"] # "morsel", "buffee"
const PICKAXE_STENGTH_POWER: Array[String] = ["flimsy", "modest", "average", "strong"] # "gentle", "modest", "powerful", "extream", "unstoppable"

@onready var label = $RichTextLabel

func _ready():
	position = get_global_mouse_position() + MOUSE_OFFSET

func set_slot(slot: InventorySlot):
	size.y = 0
	if slot.is_empty():
		label.text = ""
		return
	
	var item: InventoryItem = ResourceManager.get_item(slot.item_id)
	var lines: Array[String] = []
	
	lines.append("[color='white']%s" % [item.name])
	
	if item.description != "": 
		lines.append("[color='gray']%s" % [item.description])
	
	if item.tool_strength != 0:
		match item.tool_type:
			InventoryItem.ToolType.Pickaxe:
				var breaks = PICKAXE_STENGTH_POWER[item.tool_strength - 1]
				lines.append("[color='cyan']Power:  %s" % [breaks.capitalize()])
			InventoryItem.ToolType.Spear:
				var time = FishingInterface.SPEAR_STRENGTH_TIMES[item.tool_strength - 1]
				lines.append("[color='cyan']Speed:  %ss" % [time])
		
	if item.max_durability != 0:
		lines.append("[color='cyan']Health: %s/%s" % [slot.remaining_durability, item.max_durability])
	
	if item.meal_value != 0:
		var meal_name = MEAL_VALUE_NAMES[slot.meal_value]
		lines.append("[color='cyan']Size: %s" % [meal_name.capitalize()])
	
	label.text = DialogueManager.parse_text("\n".join(lines))

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		position = event.position + MOUSE_OFFSET
