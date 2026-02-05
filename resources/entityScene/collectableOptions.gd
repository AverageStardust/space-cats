extends Resource
class_name CollectableOptions

enum BreakSound {
	rock,
	rustle,
	wood
}

@export_category("display")
@export var texture_offset: Vector2i
@export var broken_texture_offset: Vector2i
@export var sound: BreakSound

@export_category("break")
@export var break_time := 0.25
@export var break_stength := 0
@export var tool_type: InventoryItem.ToolType
@export var custom_interaction: String

@export_category("drops")
@export var drops: Array[String] = []
@export var regrow_time := 90.0
@export var fertilizable := false
