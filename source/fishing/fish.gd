extends Resource
class_name Fish

enum MovementPattern {
	Line,
	Sine,
	ZigZag
}

@export var speed: float = 40.0
@export var pattern: MovementPattern
@export var size: float = 18.0
@export var item_id: String
@export var spawn_threshold := 0
