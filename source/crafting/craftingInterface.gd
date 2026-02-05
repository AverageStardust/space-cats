extends HBoxContainer
class_name CraftingInterface

@onready var world = SceneManager.get_current_scene("world")
@onready var input: VolumeInterface = $Input
@onready var icon: RecipeIcon = $RecipeIcon
@onready var output: VolumeInterface = $Output
@onready var output_slot := output.slot_interfaces[0]
@onready var fail_sound = $FailSound

var crafting_options: CraftingDeviceOptions: set = set_crafting_options
var recipes := {}
var current_recipe_id := ""

func _ready():
	input.volume.slots_changed.connect(on_input_changed)
	output_slot.empty_slot.connect(on_output_empty)

func on_output_empty(_slot, max_amount: int):
	if get_ingredient_count() == 0: return
	if current_recipe_id != "":
		craft_recipe(max_amount)
	else:
		fail_recipe()

func craft_recipe(max_amount: int):
	var amount = min(max_amount, get_ingredient_count())
	
	var result_slot = InventorySlot.new(amount, recipes[current_recipe_id].result_id)
	world.player.take_slot(result_slot)
	
	SaveManager.state.discover(&"recipe", current_recipe_id)
	
	take_from_slots(amount)

func fail_recipe():
	get_parent().shake(12)
	match crafting_options.failure_result:
		"none":
			pass
		"random":
			var ingredient_ids = get_ingredient_ids()
			var lose_index = randi_range(0, ingredient_ids.size() - 1)
			for index in ingredient_ids.size():
				if index == lose_index: continue
				world.player.drop_slot(InventorySlot.new(1, ingredient_ids[index]), 0)
		"ash":
			world.player.drop_slot(InventorySlot.new(1, "ash"), 0)
	
	take_from_slots()
	fail_sound.play()

func take_from_slots(amount = 1):
	for slot in input.volume.slots:
		if not slot.is_empty():
			assert(slot.remove(amount))

func on_input_changed():
	output_slot.slot.set_amount_item(0)
	current_recipe_id = ""
	
	var ingredient_ids = get_ingredient_ids()
	if ingredient_ids.size() == 0: return
	
	for recipe_id in recipes.keys():
		if recipes[recipe_id].match_recipe(ingredient_ids):
			current_recipe_id = recipe_id
			break
	
	if current_recipe_id != "" and SaveManager.state.is_discovered(&"recipe", current_recipe_id):
		output_slot.slot.set_amount_item(get_ingredient_count(), recipes[current_recipe_id].result_id)
	else:
		output_slot.slot.set_amount_item(1, "unknown")

func get_ingredient_ids():
	var ingredient_ids: Array[String] = []
	
	for slot in input.volume.slots:
		if not slot.is_empty():
			ingredient_ids.append(slot.item_id)
	
	return ingredient_ids

func get_ingredient_count():
	var count := 0
	
	for slot in input.volume.slots:
		if not slot.is_empty():
			if count == 0:
				count = slot.amount
			else:
				count = min(count, slot.amount)
	
	return count

func set_crafting_options(value: CraftingDeviceOptions):
	crafting_options = value
	
	input.volume.capacity = crafting_options.capacity
	var folder = "recipe/" + crafting_options.recipe_folder
	var prefix = crafting_options.recipe_folder + "/"
	recipes = ResourceManager.get_resources(folder, "recipe", prefix)
	
	icon.recipe_folder = crafting_options.recipe_folder

func move_focus_away():
	input.move_focus_away()
	for slot in input.volume.slots:
		world.player.take_slot(slot)
