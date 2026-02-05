extends Node

signal input_source_changed
signal interaction_dismissed
signal holder_changed
signal slot_interface_focused(interface: SlotInterface)

var ITEM_HOLDER_SCENE = ResourceManager.get_packed_scene("ui/itemHolder.tscn")
var TOOLTIP_SCENE = ResourceManager.get_packed_scene("ui/tooltip.tscn")
const ATLAS_PATH = "res://assets/atlas/buttonHint.json.txt"
const ICON_SIZE = 16
const INTERACTION_DISMISS_THRESHOLD = GlobalManager.MAX_INT

var input_source = "keyboard": set = set_input_source
var button_atlas: Dictionary
var item_holder: ItemHolder = null: set = set_item_holder
var tooltip: Tooltip = null

func _ready():
	print(ATLAS_PATH)
	var atlas_json = FileAccess.get_file_as_string(ATLAS_PATH)
	print(atlas_json)
	button_atlas = JSON.parse_string(atlas_json)

func _input(event):
	var event_source = classify_input_source(event)
	if event_source != null:
		input_source = event_source

func get_tooltip() -> Tooltip:
	if tooltip != null:return tooltip
	
	tooltip = TOOLTIP_SCENE.instantiate()
	
	SceneManager.get_current_scene("world").interface.add_child(tooltip)
	
	return tooltip

func dismiss_tooltip():
	tooltip.queue_free()
	tooltip = null
	
func set_item_holder(value):
	item_holder = value
	if item_holder == null: return
	item_holder.slot.changed.connect(func(): holder_changed.emit())
	holder_changed.emit()

func get_item_holder() -> ItemHolder:
	if has_item_holder():
		return item_holder
	
	var holder = ITEM_HOLDER_SCENE.instantiate()
	holder.tree_exiting.connect(func(): item_holder = null)
	item_holder = holder
	
	SceneManager.get_current_scene("world").interface.add_child(holder)
	
	return holder

func has_item_holder():
	return item_holder != null

func emit_slot_focused(interface: SlotInterface):
	slot_interface_focused.emit(interface)

func set_input_source(value):
	if input_source == value: return
	input_source = value
	input_source_changed.emit()

func count_interaction(interaction: String):
	SaveManager.state.increment_interaction(interaction)
	if SaveManager.state.get_interaction_count(interaction) >= INTERACTION_DISMISS_THRESHOLD:
		interaction_dismissed.emit()

func is_interaction_dismissed(interaction: String):
	if interaction == &"": return false
	return SaveManager.state.get_interaction_count(interaction) >= INTERACTION_DISMISS_THRESHOLD

func action_to_icon_uv(action: StringName):
	var event = best_event(InputMap.action_get_events(action))
	if event == null:
		printerr("Failed to choose event for action \"%s\" on input source \"%s\"" % [action, InputManager.input_source])
		return null
	
	var event_id = event_to_id(event)
	if not button_atlas.has(event_id):
		printerr("Failed to find uv for event_id \"%s\"" % [event_id])
		return null
	
	var uv = button_atlas.get(event_id)
	return Vector2(uv[0], uv[1]) * ICON_SIZE

func event_to_id(event: InputEvent):
	if event is InputEventKey:
		return "keyboard %s" % [event.as_text_physical_keycode()]
	elif event is InputEventMouseButton:
		return "mouse %s" % [event.button_index]
	elif event is InputEventJoypadButton:
		return "%s %s" % [InputManager.input_source, event.button_index]
	elif event is InputEventJoypadMotion:
		var axis_sign = "+" if event.axis_value >= 0 else "-"
		return "axis %s%s" % [axis_sign, event.axis]
	return null

func best_event(events: Array[InputEvent]):
	for event in events:
		if InputManager.input_source == "keyboard":
			if event is InputEventKey or event is InputEventMouseButton:
				return event
		else:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				return event
	
	return null

func classify_input_source(event: InputEvent):
	if event is InputEventKey or event is InputEventMouseButton:
		return "keyboard"
	
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return null
	
	var joy_name = Input.get_joy_name(0)
	
	# by console name
	if "Xbox" in joy_name:
		return "xbox"
	elif "PlayStation" in joy_name or "DualShock" in joy_name:
		return "playstation"
	elif "Nintendo Switch" in joy_name or "Wii U Pro" in joy_name or "Wii Classic" in joy_name:
		return "nintendo"
	
	# by console nickname
	if "PS3" in joy_name or "PS4" in joy_name or "PS5" in joy_name:
		return "playstation"
	elif "Switch" in joy_name:
		return "nintendo"
	
	# by company name
	if "Steam" in joy_name:
		return "xbox"
	elif "Sony" in joy_name:
		return "playstation"
	elif "Nintendo" in joy_name:
		return "nintendo"
	
	printerr("Unknown controller detected \"%s\"" % [joy_name])
	return "xbox"
