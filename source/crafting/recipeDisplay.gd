extends PanelContainer
class_name RecipeDisplay

const UPDATES_PER_SECOND := 1.2

@onready var input: VolumeInterface = $BoxContainer/Input
@onready var icon: RecipeIcon = $BoxContainer/RecipeIcon
@onready var output: VolumeInterface = $BoxContainer/Output

@export var recipe_id := "": set = set_recipe_id

var recipe_folder := ""
var recipe: Recipe = null
var time := 0.0
var updates := 0

func _process(delta):
	if recipe == null or recipe.item_tags.size() == 0: return
	
	time += delta
	if floori(time * UPDATES_PER_SECOND) < updates: return
	update_input_slots()
	updates += 1

func set_recipe_id(value: String):
	recipe_id = value
	recipe_folder = recipe_id.split("/")[0]
	recipe = ResourceManager.get_recipe(recipe_id)
	
	if not is_node_ready(): await ready
	
	input.volume = InventoryVolume.new(recipe.size())
	output.volume = InventoryVolume.new(1)
	icon.recipe_folder = recipe_folder
	
	update_input_slots()
	
	output.volume.slots[0].set_amount_item(1, recipe.result_id)
	output.slot_interfaces[0].mouse_default_cursor_shape = Control.CURSOR_ARROW

func update_input_slots():
	if not is_node_ready(): await ready
	
	var previous_items = {}
	
	for i in recipe.size():
		var item_id: String
		
		if i < recipe.item_tags.size():
			var item_ids = ResourceManager.get_items_by_tag(recipe.item_tags[i])
			item_id = item_ids.pick_random()
			for _j in 100:
				if not previous_items.has(item_id): break
				item_id = item_ids.pick_random()
		else:
			item_id = recipe.item_ids[i]
		
		previous_items[item_id] = true
		input.volume.slots[i].set_amount_item(1, item_id)
		input.slot_interfaces[i].mouse_default_cursor_shape = Control.CURSOR_ARROW
