extends Resource
class_name InventoryItem

enum ItemTag {
	Vegetable,
	Fruit,
	Berry,
	Flower,
	Fish
}

enum ToolType {
	None,
	Pickaxe,
	Spear
}

@export var name := ""
@export_multiline var description := ""
@export var texture_offset: Vector2i
@export var stack_size := 99
@export var tags: Array[ItemTag] = []
@export var entity := ""
@export var meal_value := 0

@export_category("Tool")
@export var tool_type: ToolType = ToolType.None
@export var tool_strength := 0
@export var tool_specialty := ""
@export var max_durability := 0
