extends Resource
class_name Settings

const WINDOW_FACTOR = Vector2i(640, 360)
const MIN_VOLUME_DB = -60.0
const VOLUME_LEVELS = 10

@export var windowed_size = WINDOW_FACTOR * 2: set = set_windowed_size
@export var fullscreen = true: set = set_fullscreen
@export var volumes = {
	"Master": 1.0,
	"Dialogue": 1.0,
	"Interface": 1.0,
	"Music": 1.0,
	"World": 1.0
}

func set_windowed_size(value):
	windowed_size = round_int_window_size(value)
	emit_changed()

func set_fullscreen(value):
	fullscreen = value
	emit_changed()

func set_volume_level(bus_name: String, level: int):
	volumes[bus_name] = float(level) / float(VOLUME_LEVELS)
	emit_changed()

func get_volume_level(bus_name: String):
	return roundi(volumes[bus_name] * VOLUME_LEVELS)

func get_volume_db(bus_name: String):
	return lerp(MIN_VOLUME_DB, 0.0, sqrt(volumes[bus_name]))

func get_muted(bus_name: String):
	return volumes[bus_name] <= 0.0

func round_int_window_size(size: Vector2i):
	var intager =  Vector2(size) / Vector2(WINDOW_FACTOR)
	intager = max(1, roundi(min(intager.x, intager.y)))
	size = WINDOW_FACTOR * intager
	return size
