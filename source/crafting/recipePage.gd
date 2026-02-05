extends ScrollContainer
class_name RecipePage

var RECIPE_DISPLAY_SCENE = ResourceManager.get_packed_scene("crafting/recipeDisplay.tscn")

@onready var flow_container = $FlowContainer

var sort_queued = false

func _process(_delta):
	if sort_queued:
		sort_queued = false
		sort_children()

func add_recipe(recipe_id: String):
	var display = RECIPE_DISPLAY_SCENE.instantiate()
	display.recipe_id = recipe_id
	flow_container.add_child(display)
	sort_queued = true

func sort_children():
	var sorted_nodes := flow_container.get_children()
	sorted_nodes.sort_custom(sort_func)

	for node in flow_container.get_children():
		flow_container.remove_child(node)

	for node in sorted_nodes:
		flow_container.add_child(node)

func sort_func(a: Node, b: Node):
	return a.recipe_id.naturalnocasecmp_to(b.recipe_id) < 0
