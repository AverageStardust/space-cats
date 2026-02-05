extends Resource
class_name MusicRegion

@export var start_angle: float
@export var end_angle: float
@export var volumes: Array[float]

func contains_angle(angle: float):
	if start_angle < end_angle:
		return start_angle < angle and angle < end_angle
	else:
		return angle > start_angle or angle < end_angle
