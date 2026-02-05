extends Polygon2D

const POINT_COUNT = 64
const WIDTH = 768
const HEIGHT = 96

var start_y: float
var time := randf_range(0, TAU)
var float_rate := randf_range(5.0, 12.0)
var wave_height := randf_range(4.0, 8.0)
var time_speed := randf_range(0.8, 1.2)
var wave_phase := randf_range(0, TAU)
var wave_phase_rate := randf_range(1.0, 2.0)

func _ready():
	var verts = PackedVector2Array()
	var uvs = PackedVector2Array()
	
	for i in POINT_COUNT:
		var x_left = float(i) / float(POINT_COUNT) * WIDTH
		var x_right = float(i + 1) / float(POINT_COUNT) * WIDTH
		
		var index = verts.size()
		verts.append(Vector2(x_left, 0))
		verts.append(Vector2(x_right, 0))
		verts.append(Vector2(x_right, HEIGHT))
		verts.append(Vector2(x_left, HEIGHT))
		
		polygons.append(PackedInt32Array([index + 0, index + 1, index + 2, index + 3]))
	
	polygon = verts
	uv = uvs
	
	start_y = position.y

func _process(delta):
	time += delta * time_speed
	position.y = start_y + sin(time) * wave_height
	position.x += delta * (cos(time) * 8.0 - float_rate)
	wave_phase += delta * wave_phase_rate
	
	if position.x > -96:
		position.x -= 192
	elif position.x < -288:
		position.x += 192
		
	material.set_shader_parameter("wave_phase", wave_phase)
