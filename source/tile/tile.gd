extends Resource
class_name Tile

signal surface_changed
signal entity_changed

@export var curvature: float
@export var outer_radius: float
@export var inner_radius: float
@export var surface_id: String = "home/ground": set = set_surface_id 
@export var entity_id: String = "": set = set_entity_id
@export var entity_state: Resource = null

func set_surface_id(value):
	surface_id = value
	surface_changed.emit()
	emit_changed()
	
func set_entity_id(value):
	entity_id = value
	entity_state = null
	if entity_id != "":
		var inital_state = ResourceManager.get_entity(entity_id).inital_state
		if inital_state != null:
			entity_state = inital_state.duplicate()
	entity_changed.emit()
	emit_changed()

func is_water():
	# true if open water, not docks
	if ResourceManager.get_surface(surface_id).water:
		if entity_id == "": return true
		return not ResourceManager.get_entity(entity_id).water_platform
	
	return false
	
func is_land():
	# true if flat land, not docks
	return not ResourceManager.get_surface(surface_id).water
