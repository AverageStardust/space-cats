extends Resource
class_name CollectableState

@export var broken = false: set = set_broken
@export var broken_time: float: set = set_broken_time

func set_broken_time(value: float):
	if broken_time == value: return
	broken_time = value
	broken = broken_time > 0

func set_broken(value):
	if broken == value: return
	broken = value
	emit_changed()
