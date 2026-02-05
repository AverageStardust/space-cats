extends Resource
class_name Ship

const REFUEL_RATE := 25.0
const FULL_REPAIR := 4

@export var actor: Actor
@export var boarded := false
@export var max_fuel := 100.0
@export var current_fuel := 100.0
@export var repairs := 0: set = set_repairs

func get_fuel_percent():
	var percent = ceili(current_fuel / max_fuel * 100.0)
	return "%3d%%" % percent

func reset():
	reset_position()
	current_fuel = max_fuel
	boarded = false
	repairs = 0

func refuel(delta):
	current_fuel = move_toward(current_fuel, max_fuel, delta * REFUEL_RATE)

func set_repairs(value):
	repairs = value
	emit_changed()

func is_repaired():
	return repairs >= FULL_REPAIR

func reset_position():
	actor.position = Vector2(71, -71)
	actor.rotation = TAU / 8
