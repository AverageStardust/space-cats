extends Node
class_name Dialogue

signal loaded
signal closed
signal kiss

const PROMPT_NUMBERS = [1, 2, 3, 5, 8, 10, 15, 20, 30, 50, 80, 100]
const MEAL_POINTS = [5, 7, 10, 12]
const MEAL_REWARDS = [
[
	"twig",
	"stone",
	"fiber",
	"strawberry"
], [
	"flint",
	"log",
	"coal",
	"anchovy"
], [
	"ironOre",
	"coal",
	"tuna"
], [
	"mechanism",
	"copperOre",
	"salmon"
]]

@onready var ink_player = InkPlayer.new()

var world: World
var save: SaveGame
var dialogue_interface: DialogueInterface
var dialogue_panel: Control
var recipes := {}

var dialogue_id = ""
var is_loaded = false
var is_open = false

func _init(_dialogue_id: String):
	dialogue_id = _dialogue_id

func _ready():
	add_child(ink_player)
	ink_player.ink_file = load("res://assets/story/%s.ink.json" % [dialogue_id])
	ink_player.loads_in_background = true

	ink_player.loaded.connect(on_story_loaded)
	ink_player.continued.connect(on_story_text)
	ink_player.prompt_choices.connect(on_story_choices)
	ink_player.ended.connect(close)
	
	ink_player.create_story()

func on_story_loaded(successfully: bool):
	if !successfully: 
		push_error("Failed to load ink story")
		return
	
	bind_functions()
	
	is_loaded = true
	loaded.emit()

func on_story_text(text: String, tags: Array):
	await prompt_text(text, tags)
	ink_player.continue_story()

func on_story_choices(choices: Array):
	choices = choices.map(func (choice): return choice.text)
	var index = await prompt_choices(choices)
	ink_player.choose_choice_index(index)
	ink_player.continue_story()

func bind_functions():
	ink_player.bind_external_function("GET_MEAL_COUNT", get_meal_count)
	ink_player.bind_external_function("PROMPT_MEAL_ID", prompt_meal_id)
	ink_player.bind_external_function("GET_HOTBAR_AMOUNT", get_hotbar_amount)
	ink_player.bind_external_function("PROMPT_MEAL_REWARD", prompt_meal_reward)
	ink_player.bind_external_function("DO_TRADE", do_trade)
	
	ink_player.bind_external_function("USE_HINT", use_hint)
	ink_player.bind_external_function("GET_HINT_RECIPE_ID", get_hint_recipe_id)
	ink_player.bind_external_function("GET_UNCRAFTED_ITEM_ID", get_uncrafted_item_id)
	ink_player.bind_external_function("GET_RECIPE_INGREDIENTS", get_recipe_ingredients)
	ink_player.bind_external_function("GET_RECIPE_RESULT", get_recipe_result)
	ink_player.bind_external_function("DISCOVER_RECIPE", discover_recipe)
	ink_player.bind_external_function("EMIT_KISS", emit_kiss)
	
	ink_player.bind_external_function("HINT_AVAILABLE", hint_available)
	ink_player.bind_external_function("PROMPT_AMOUNT", prompt_amount)
	ink_player.bind_external_function("PROMPT_CONFIRM", prompt_confirm)

# EXTERNAL FUNCTIONS

func get_meal_count():
	var meals = world.hotbar.volume.get_meal_slots()
	return meals.size()

func prompt_meal_id():
	var meals = world.hotbar.volume.get_meal_slots()
	
	if meals.size() == 0: 
		return ""
	
	var choices = meals.map(func (slot): return slot.item_name)
	choices.append("Nothing")
	
	var index = await prompt_choices(choices)
	
	if index == choices.size() - 1:
		return ""
	
	return meals[index].item_id

func get_hotbar_amount(item_id: String):
	return world.hotbar.volume.removeable_amount(item_id)

func prompt_meal_reward(item_id: String):
	var item = ResourceManager.get_item(item_id)
	var rewards = MEAL_REWARDS[item.meal_value - 1]
	var choices: Array[String] = []
	
	for reward in rewards:
		var reward_item = ResourceManager.get_item(reward)
		choices.append(reward_item.name)
	
	return rewards[await prompt_choices(choices)]

func do_trade(meal_item_id: String, amount: int, reward_item_id: String):
	if world.hotbar.volume.remove(amount, meal_item_id):
		world.player.take_slot(InventorySlot.new(amount, reward_item_id))
		var meal_item = ResourceManager.get_item(meal_item_id)
		var points = MEAL_POINTS[meal_item.meal_value - 1] * amount
		save.hints_points += points
		return true
	else:
		return false

func hint_available():
	return save.hints_points >= 10

func use_hint():
	if save.hints_points >= 10:
		save.hints_points -= 10
		return true
	else:
		return false

func get_hint_recipe_id():
	var recipe_ids = []
	
	for recipe_id in recipes.keys():
		if save.is_discovered(&"recipe", recipe_id): continue
		var folder = recipe_id.split("/")[0]
		if not save.is_discovered(&"recipe_folder", folder): continue
		if recipes[recipe_id].craftable(save):
			recipe_ids.append(recipe_id)
	
	if recipe_ids.size() == 0:
		return ""
	
	return recipe_ids.pick_random()

func get_uncrafted_item_id():
	var item_ids = {}
	
	for recipe_id in recipes.keys():
		if not save.is_discovered(&"recipe", recipe_id): continue
		var result_id = recipes[recipe_id].result_id
		if save.is_discovered(&"item", result_id): continue
		item_ids[result_id] = true
	
	if item_ids.size() == 0:
		return ""
	
	return item_ids.keys().pick_random()

func get_recipe_ingredients(recipe_id: String):
	var ingredients = recipes[recipe_id].get_ingredient_codes()
	if ingredients.size() == 1: 
		return "a %s" % ingredients[0]
	
	if ingredients.size() == 2:
		return "%s and %s" % [ingredients[0], ingredients[1]]
	
	var last_ingredient = ingredients.pop_back()
	return "%s, and %s" % [", ".join(ingredients), last_ingredient]

func get_recipe_result(recipe_id: String):
	return "<item=%s>" % recipes[recipe_id].result_id

func discover_recipe(recipe_id: String):
	save.discover(&"recipe", recipe_id)

func emit_kiss():
	kiss.emit()

func prompt_amount(max_amount: int):
	var choices: Array[String] = []
	
	for number in PROMPT_NUMBERS:
		if number >= max_amount: break
		choices.append("%s" % [number])
	
	choices.append("%s" % [max_amount])
	
	return choices[await prompt_choices(choices)].to_int()

func prompt_confirm() -> bool:
	var index = await prompt_choices(["Yes", "No"])
	return ([true, false])[index]
	
# STORY DIALOGUE

func open(path := "start"):
	if not is_loaded: await loaded
	if is_open: return
	
	update_world()
	
	is_open = true
	dialogue_panel.visible = true
	dialogue_interface.name_label.text = "[color=cyan]%s[/color]" % dialogue_id.capitalize()
	ink_player.choose_path(path)
	ink_player.continue_story()

func update_world():
	var _world = SceneManager.get_current_scene("world")
	if world == _world: return
	
	world = _world
	save = world.save
	dialogue_interface = world.dialogue
	dialogue_panel = world.dialogue_panel
	
	recipes = ResourceManager.get_resources("recipe", "recipe")
	
	if save.dialogue_states.has(dialogue_id):
		ink_player.set_state(save.dialogue_states[dialogue_id])

func close(force = false):
	if not is_loaded: await loaded
	if not is_open: return
	
	save.dialogue_states[dialogue_id] = ink_player.get_state()
	
	if not force:
		await dialogue_interface.prompt_continue()
	
	is_open = false
	dialogue_panel.visible = false
	dialogue_interface.clear_text()
	closed.emit()

func prompt_text(text: String, tags: Array = []):
	await dialogue_interface.set_tags(tags)
	
	if text.strip_edges().length() > 0:
		dialogue_interface.add_text(DialogueManager.parse_text(text))

func prompt_choices(choices: Array):
	if choices.is_empty(): return
	dialogue_interface.add_choices(choices)
	var index = await dialogue_interface.choice_made
	dialogue_interface.clear_text()
	return index
