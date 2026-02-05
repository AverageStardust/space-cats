extends Control

const empty_entity = "null"

@onready var window = get_parent()
@onready var logger = $VBoxContainer/RichTextLabel
@onready var input = $VBoxContainer/LineEdit

var commands = Dictionary()
var player: PlayerBody

var current_line = null
var previous_lines: Array[String] = []
var previous_line_index = null

func _ready():
	var surface_argument = Argument.new("surface_id", ResourceManager.list_resources("surface"))
	var entities = ResourceManager.list_resources("entity")
	entities.push_back(empty_entity)
	var entity_argument = Argument.new("entity_id", entities)
	var item_argument = Argument.new("surface_id", ResourceManager.list_resources("item"))
	var amount_argument = Argument.new("amount", [], as_int)
	
	commands["help"] = Command.new(help_command, [])
	commands["noclip"] = Command.new(noclip_command, [])
	commands["resize"] = Command.new(resize_command, [amount_argument])
	commands["surface"] = Command.new(surface_command, [surface_argument])
	commands["entity"] = Command.new(entity_command, [entity_argument])
	commands["fill"] = Command.new(fill_command)
	commands["saveinit"] = Command.new(save_initial_command)
	commands["loadinit"] = Command.new(load_initial_command)
	commands["give"] = Command.new(give_command, [item_argument, amount_argument], 1)
	
	assign_player.call_deferred()

func assign_player():
	player = SceneManager.get_current_scene("world").player

func help_command():
	for command in commands:
		var args = commands[command].args
		var arg_string = ""
		
		for arg in args:
			arg_string += "<%s>" % [arg.name]
		
		send_message("%s %s" % [command, arg_string])

func noclip_command():
	player.noclip = not player.noclip
	send_message("Enabled" if player.noclip else "Disabled")

func surface_command(args):
	var surface_id = args[0]
	player.surface_brush = surface_id
	player.entity_brush = null
	send_message("Surface brush set to \"%s\"" % [surface_id])
	
func entity_command(args):
	var entity_id = args[0]
	if entity_id == empty_entity:
		entity_id = ""
	player.surface_brush = null
	player.entity_brush = entity_id
	send_message("Entity brush set to \"%s\"" % [entity_id])

func fill_command():
	var celestial_body = get_celestial_body()
	if celestial_body == null: return
	
	for tile in celestial_body.celestial.tiles:
		player.brush_tile(tile)
	
	send_message("Celestial filled")

func resize_command(args):
	var celestial_body = get_celestial_body()
	if celestial_body == null: return
	
	var tile_count = args[0]
	celestial_body.celestial.resize_tiles(tile_count)
	send_message("Celestial resized to %s tiles" % [tile_count])

func save_initial_command():
	SaveManager.save_init()
	send_message("Saved as initial state")
	
func load_initial_command():
	SaveManager.load_init()
	send_message("Loaded initial state")

func give_command(args):
	var item_id = args[0]
	var amount = 1
	if args.size() > 1: amount =  args[1]
	var slot = InventorySlot.new(amount, item_id)
	if player.player.volume.transfer(slot):
		send_message("Gave %s %s" % [amount, item_id])
	else:
		send_error("Inventory overflowed")
		

func get_celestial_body() -> CelestialBody:
	if not (player.surface is CelestialBody):
		send_error("Not on celestial")
		return null
	
	return player.surface

func _input(event):
	if not(event is InputEventKey): return
	
	if event.is_action_pressed("console_toggle"):
		toggle()
	elif event.is_action_pressed("ui_text_submit"): 
		execute_input()
	elif event.is_action_pressed("console_complete"):
		set_input_text(complete(input.text))
	elif event.is_action_pressed("ui_up"):
		select_last_command()
	elif event.is_action_pressed("ui_down"):
		select_next_command()
	else:
		return
	
	accept_event()

func toggle():
	if not GlobalManager.DEV: return
	
	window.visible = not window.visible
	if window.visible:
		input.grab_focus()

func execute_input():
	execute(input.text)
	previous_lines.push_back(input.text)
	input.text = ""
	current_line = null
	previous_line_index = null

func select_last_command():
	if previous_line_index == null:
		if previous_lines.size() > 0:
			current_line = input.text
			previous_line_index = previous_lines.size() - 1
			set_input_text(previous_lines[previous_line_index])
	elif previous_line_index > 0:
		previous_line_index -= 1
		set_input_text(previous_lines[previous_line_index])

func select_next_command():
	if previous_line_index == null: return
	if previous_line_index < previous_lines.size() - 1:
		previous_line_index += 1
		set_input_text(previous_lines[previous_line_index])
	else:
		previous_line_index = null
		set_input_text(current_line)

func set_input_text(text):
	input.text = text
	input.caret_column = text.length()

func execute(line: String):
	var parse_result = parse(line)
	if parse_result.command != null or parse_result.error != null:
		send_command(line)
	else:
		return false
	
	if parse_result.error != null:
		send_error(parse_result.error)
		return false
	
	if parse_result.args.size() > 0:
		parse_result.command.function.call(parse_result.args)
	else:
		parse_result.command.function.call()
	return true

func complete(line: String):
	var words = split_tokens(line)
	if words.size() == 0: return ""
		
	var completions = parse(line).completions
	var last_word = words.pop_back()
	var common_completion = null
	
	for completion in completions:
		if completion.begins_with(last_word):
			if common_completion == null:
				common_completion = completion
			else:
				common_completion = common_beginning(common_completion, completion)
	
	if common_completion == null:
		words.push_back(last_word)
	else:
		words.push_back(common_completion)
	
	return " ".join(words)

func common_beginning(a: String, b: String):
	for i in a.length():
		if a[i] != b[i]:
			return a.substr(0, i)
	return a

func parse(line: String):
	var args = split_tokens(line)
	
	var command = args.pop_front()
	
	if command == null:
		return ParseResult.new(null, [], null)
	
	if command not in commands:
		return ParseResult.new(null, [], "Unknown command \"%s\"" % [command], commands.keys())
	
	command = commands[command]
	
	if args.size() < command.required_args:
		var arg = command.args[args.size()]
		return ParseResult.new(command, args, "Missing argument %s" % [arg.name], arg.options)
	
	if args.size() > command.args.size():
		return ParseResult.new(command, args, "Too many arguemnts")
	
	for i in args.size():
		var arg = args[i]
		var command_arg: Argument = command.args[i]
		
		if (command_arg.options.size() > 0 and command_arg.options.find(arg) == -1):
			var error = "Invalid argument %s=\"%s\"" % [command_arg.name, arg]
			return ParseResult.new(command, args, error, command_arg.options)
		
		arg = command_arg.converter.call(arg)
		
		args[i] = arg
	
	return ParseResult.new(command, args)

func split_tokens(line: String):
	return Array(line.strip_edges().split(" ", false))

func send_message(text):
	send_raw("[color=gray]%s[/color]" % [text])

func send_error(text):
	send_raw("[color=red]%s[/color]" % [text])

func send_command(text):
	send_raw("[color=white][i]%s[/i][/color]" % [text])

func send_raw(text: String):
	logger.append_text(text)
	logger.newline()

class ParseResult:
	var command
	var args
	var error
	var completions

	func _init(_command, _args, _error = null, _completions = []):
		command = _command
		args = _args
		error = _error
		completions = _completions

class Command:
	var function: Callable
	var args
	var required_args
	
	func _init(_function, _args = [], _required_args = null):
		function = _function
		args = _args
		if _required_args == null:
			required_args = _args.size()
		else:
			required_args = _required_args

class Argument:
	var name: String
	var options: PackedStringArray
	var converter: Callable
	
	func _init(_name, _options = PackedStringArray(), _converter: Callable = func (s): return s):
		name = _name
		options = _options
		converter = _converter

func as_int(arg: String):
	if not arg.is_valid_int():
		return null
	return arg.to_int()
