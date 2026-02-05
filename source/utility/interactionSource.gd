extends Area2D
class_name InteractionSource

var nearby_boxes = {}
var focused_boxes := {}
var focus_locked = false
var pressed = false

func _process(_delta):
	if not focus_locked:
		update_focused_boxes()
		
	for focused_box in focused_boxes.values():
		focused_box.focused = true
	
	pressed = false
	for box in focused_boxes.values():
		if box.pressed:
			pressed = true

func lock_focus(_focused_boxes):
	focused_boxes = _focused_boxes
	focus_locked = true

func unlock_focus():
	focus_locked = false

func update_focused_boxes():
	var nearest_boxes = find_nearest_boxes()
	for key in focused_boxes.keys():
		if focused_boxes[key] != nearest_boxes.get(key):
			if is_instance_valid(focused_boxes[key]):
				focused_boxes[key].focused = false
	
	for box in nearest_boxes.values():
		box.focused = true
		
	focused_boxes = nearest_boxes
	
func find_nearest_boxes():
	var nearest_dists = {}
	var nearest_boxes = {}
	
	for box in nearby_boxes.values():
		if not box.enabled: continue
		var key = box.action
		var dist = box.global_position.distance_to(global_position)
		if dist < nearest_dists.get(key, INF):
			nearest_dists[key] = dist
			nearest_boxes[key] = box
	
	return nearest_boxes

func _input(event):
	for focused_box in focused_boxes.values():
		if is_instance_valid(focused_box):
			focused_box.on_source_event(event)

func _on_area_entered(area: Area2D):
	if not is_instance_of(area, InteractionBox): return
	nearby_boxes[area.get_rid()] = area
	area.in_range = true

func _on_area_exited(area: Area2D):
	if not is_instance_of(area, InteractionBox): return
	nearby_boxes.erase(area.get_rid())
	area.in_range = false
