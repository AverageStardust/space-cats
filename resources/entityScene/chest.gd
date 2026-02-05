extends EntityScene

@onready var interaction_box: InteractionBox = $InteractionBox
@onready var world = SceneManager.get_current_scene("world")
@onready var player: PlayerBody = world.player
@onready var open_sound = $OpenSound
@onready var close_sound = $CloseSound

var state: ChestState
var open := false: set = set_open

func _ready():
	interaction_box.interacted.connect(on_interacted)
	player.focus_unlocked.connect(set_open.bind(false))
	update_texture()

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
	if open == value: return
	open = value
	world.chest_panel.visible = open
	
	update_texture()
	
	if open:
		open_sound.play()
		player.lock_focus({ interaction_box.action: interaction_box})
		world.chest.top_volume_interface = world.hotbar
		world.hotbar.bottom_volume_interface = world.chest
		world.chest.volume = state.volume
	else:
		close_sound.play()
		player.unlock_focus()
		world.chest.move_focus_away()
		world.chest.top_volume_interface = null
		world.hotbar.bottom_volume_interface = null

func update_texture():
	var offset = Vector2i(1, 7) if open else Vector2i(1, 6)
	changed_texture_offset.emit(offset)
