extends EntityScene

@onready var interaction_box: InteractionBox = $InteractionBox
@onready var world = SceneManager.get_current_scene("world")
@onready var player = world.player
@onready var hotbar = world.hotbar
@onready var crafting: CraftingInterface = world.crafting

var open := false: set = set_open
var options: CraftingDeviceOptions

func _ready():
	interaction_box.interacted.connect(on_interacted)
	player.focus_unlocked.connect(set_open.bind(false))

func _exit_tree():
	if open:
		on_interacted()

func _input(event):
	if event.is_action_pressed("ui_cancel") and open:
		get_viewport().set_input_as_handled()
		open = false

func on_interacted():
	open = not open

func set_open(value):
	if value == open: return
	
	open = value
	
	world.crafting_panel.visible = open
	if open:
		world.save.discover(&"recipe_folder", options.recipe_folder)
		player.lock_focus({ interaction_box.action: interaction_box})
		crafting.crafting_options = options
		crafting.input.top_volume_interface = hotbar
		crafting.output.top_volume_interface = hotbar
		hotbar.bottom_volume_interface = crafting.input
		SoundManager.play_sound("open")
	else:
		player.unlock_focus()
		crafting.move_focus_away()
		hotbar.bottom_volume_interface = null
		crafting.input.top_volume_interface = null
		crafting.output.top_volume_interface = null
		SoundManager.play_sound("close")
