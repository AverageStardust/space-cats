extends Node

signal settings_changed()

const SAVE_RESIZE_DELAY = 0.5
const SETTINGS_PATH = "user://settings.tres"

var settings: Settings: set = set_settings
var new_windowed_size: Vector2i
var save_resize_timeout := INF

func _process(delta):
	if settings == null: return
	
	var window = get_window()
	match window.mode:
		Window.MODE_WINDOWED:
			if new_windowed_size != window.size:
				new_windowed_size = window.size
				save_resize_timeout = SAVE_RESIZE_DELAY
		Window.MODE_MAXIMIZED:
			settings.fullscreen = true
	
	save_resize_timeout -= delta
	if save_resize_timeout <= 0.0:
		save_resize_timeout = INF
		settings.windowed_size = new_windowed_size

func _unhandled_input(event):
	if event.is_action_pressed("toggle_fullscreen"):
		settings.fullscreen = not settings.fullscreen

func load_or_init():
	if ResourceLoader.exists(SETTINGS_PATH):
		set_settings(load(SETTINGS_PATH))
	else:
		set_settings(Settings.new())

func save():
	if settings == null: return
	ResourceSaver.save(settings, SETTINGS_PATH)

func set_settings(value):
	if settings: settings.disconnect("changed", update)
	settings = value
	settings.connect("changed", update)
	update()

func update():
	var window = get_window()
	
	if settings.fullscreen:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.set_size(settings.windowed_size)
	
	for bus_name in settings.volumes.keys():
		var bus_index = AudioServer.get_bus_index(bus_name)
		AudioServer.set_bus_volume_db(bus_index, settings.get_volume_db(bus_name))
		AudioServer.set_bus_mute(bus_index, settings.get_muted(bus_name))
	
	save()
	settings_changed.emit()
