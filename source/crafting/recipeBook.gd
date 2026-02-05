extends TabContainer

var RECIPE_PAGE_SCENE = ResourceManager.get_packed_scene("crafting/recipePage.tscn")

@onready var discovery_sound = $DiscoverySound

var pages := {}

func _ready():
	var state := SaveManager.state
	
	for recipe_id in state.get_discovery_by_type("recipe").keys():
		add_recipe(recipe_id)
	
	state.discovered.connect(on_discovered)

func _input(event):
	var parent = get_parent()
	if parent.visible and event.is_action_pressed("ui_cancel"):
		accept_event()
		parent.visible = false

func on_discovered(type: String, id):
	if type != "recipe": return
	add_recipe(id)
	discovery_sound.play()

func add_recipe(recipe_id: String):
	var page = get_recipe_id_page(recipe_id)
	page.add_recipe(recipe_id)

func get_recipe_id_page(recipe_id: String) -> RecipePage:
	var folder = recipe_id.split("/")[0]
	
	if pages.has(folder):
		return pages[folder]
	else:
		var page = RECIPE_PAGE_SCENE.instantiate()
		page.name = folder_to_name(folder)
		pages[folder] = page
		if pages.size() > 1:
			tabs_visible = true
		add_child(page)
		return page
		
func folder_to_name(folder: String) -> String:
	match folder:
		"assembly":
			return "Assembly Table"
		"campfire":
			return "Campfire"
		"smelter":
			return "Smelter"
		_:
			return "UNKNOWN"


func _on_tab_clicked(_tab):
	SoundManager.play_sound("click")
