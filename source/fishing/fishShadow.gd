extends Sprite2D
class_name FishShadow

const EDGE_BUFFER := 64
const MIN_DISTANCE := 375.0

@onready var world: World = SceneManager.get_current_scene("world")
@onready var player: PlayerBody = world.player
@onready var particles = $CPUParticles2D

@export var fish: Fish

var start_position: Vector2
var end_position: Vector2
var path_progress := 0.0
var dead := false

func _ready():
	texture.width = fish.size
	texture.height = fish.size
	particles.amount = roundi(fish.size * fish.speed / 250.0)

func _process(delta):
	if dead:
		modulate.a -= delta * 0.9
		if modulate.a <= 0:
			queue_free()
		return
	
	path_progress += fish.speed * delta
	if path_progress > (end_position - start_position).length():
		queue_free()
	
	var path_position = move_toward_vector2(start_position, end_position, path_progress)
	var normal = (end_position - start_position).normalized().rotated(TAU * 0.25)
	var pattern_offset: float
	
	match fish.pattern:
		Fish.MovementPattern.Line:
			pattern_offset = 0
		Fish.MovementPattern.Sine:
			pattern_offset = sin(path_progress / 80.0 * TAU) * 20.0
		Fish.MovementPattern.ZigZag:
			pattern_offset = pingpong(path_progress + 20.0, 40.0) - 20.0
	
	position = path_position + normal * pattern_offset

func catch():
	player.take_slot(InventorySlot.new(1, fish.item_id))
	world.save.fish_caught += 1
	dead = true

func create_path(world_size: Vector2):
	while start_position.distance_to(end_position) < MIN_DISTANCE:
		var start_side = randi_range(0, 3)
		var end_side = randi_range(0, 3)
		if start_side == end_side:
			end_side = (end_side + 2) % 4
		
		start_position = pick_edge_point(world_size, start_side)
		end_position = pick_edge_point(world_size, end_side)
	
	position = start_position

func pick_edge_point(world_size: Vector2, side: int):
	match side:
		0:
			return Vector2(-EDGE_BUFFER, randf_range(EDGE_BUFFER, world_size.y - EDGE_BUFFER))
		1:
			return Vector2(randf_range(EDGE_BUFFER * 2.0, world_size.x - EDGE_BUFFER * 2.0), -EDGE_BUFFER)
		2:
			return Vector2(world_size.x + EDGE_BUFFER, randf_range(EDGE_BUFFER, world_size.y - EDGE_BUFFER))
		3:
			return Vector2(randf_range(EDGE_BUFFER * 2.0, world_size.x - EDGE_BUFFER * 2.0), world_size.y + EDGE_BUFFER)

func move_toward_vector2(start: Vector2, end: Vector2, length: float):
	return start + (end - start).normalized() * length

func intersects(point: Vector2):
	return point.distance_to(position) < fish.size * 0.75
