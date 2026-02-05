extends Sprite2D
class_name ThrownSpear

signal hit(spear: ThrownSpear, position: Vector2)

const GRAVITY = 360.0
const TIP_OFFSET = Vector2(-10, 10)
const SNAP_TIME = 0.15
const DESPAWN_TIME = 0.9

@onready var particles = $CPUParticles2D

var start_position: Vector2
var end_position: Vector2
var init_velocity: Vector2
var path_time: float
var time: float
var landed := false

func _ready():
	position = start_position
	material = material.duplicate()

func set_path(start: Vector2, end: Vector2, _path_time: float):
	start_position = start
	end_position = end - TIP_OFFSET
	path_time = _path_time
	init_velocity = Vector2()
	init_velocity.x = (end_position.x - start_position.x) / path_time
	init_velocity.y = (end_position.y - start_position.y) / path_time - GRAVITY * path_time / 2.0
	rotation = init_velocity.angle() + TAU * -0.375
	time = 0.0

func set_spear_color(color: Color):
	material.set_shader_parameter("spear_color", color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	time += delta
	if time >= path_time:
		if not landed:
			landed = true
			particles.emitting = true
			hit.emit(self, end_position + TIP_OFFSET)
		frame = 1
		position = end_position
		rotation = 0
		if time >= path_time + DESPAWN_TIME:
			queue_free()
	else:
		frame = 0
		var velocity = init_velocity + Vector2(0.0, GRAVITY * time)
		if time >= path_time - SNAP_TIME:
			rotation = lerp_angle(rotation, 0, 0.15)
		else:
			rotation = lerp_angle(rotation, velocity.angle() + TAU * -0.375, 0.035)
		position.x = start_position.x + init_velocity.x * time
		position.y = start_position.y + init_velocity.y * time + GRAVITY * (time ** 2) / 2.0
