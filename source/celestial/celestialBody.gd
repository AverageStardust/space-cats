extends AnimatableBody2D
class_name CelestialBody

const WATER_RESOLUTION = 4
const GRAVITATIONAL_CONSTANT = 0.009

var tile_scene = ResourceManager.get_packed_scene("tile/celestialTile.tscn")

@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var occluder: LightOccluder2D = $LightOccluder2D
@onready var core: Polygon2D = $Core
@onready var water: Polygon2D = $Water
@onready var gravity: Area2D = $Area2D
@onready var gravity_shape: CollisionShape2D = $Area2D/CollisionShape2D

@export var celestial: Celestial: set = set_celestial

var celestial_tiles: Array[CelestialTile] = []
var wave_phase: float = randf() * TAU

func _process(delta):
	update_position(delta)
	wave_phase = fmod(wave_phase + delta, TAU)
	water.material.set_shader_parameter("wave_phase", wave_phase)

func get_system_bodies():
	var bodies: Array[CelestialBody] = [self]
	
	for child in get_children():
		if child is CelestialBody:
			bodies.append(child)
			bodies.append_array(child.get_system_bodies())
	
	return bodies

func set_celestial(value):
	if value.tiles.size() == 0: return
	if celestial: 
		celestial.disconnect("changed", update_celestial)
		value.copy_likeness(celestial)
		
	celestial = value
	celestial.connect("changed", update_celestial)
	
	update_celestial()

func update_celestial():
	if not is_node_ready(): await ready
	
	for child in get_children():
		if child is CelestialBody:
			if celestial.satellites.has(child.name):
				child.celestial = celestial.satellites[child.name]
			else:
				celestial.satellites[child.name] = child.celestial
	
	collider.shape = CircleShape2D.new()
	collider.shape.radius = celestial.radius - 8
	update_position(0)
	
	generate_core(celestial.radius - 24)
	generate_water(celestial.radius - 8, celestial.radius - 40)
	generator_occluder(celestial.radius - 28)
	generate_gravity()
	generate_surfaces()

func update_position(delta: float):
	if celestial.orbital_radius == 0: return
	celestial.orbital_time += delta
	var angular_velocity = celestial.orbital_velocity / celestial.orbital_radius
	var angle = celestial.orbital_phase + angular_velocity * celestial.orbital_time
	position = Vector2.from_angle(angle) * celestial.orbital_radius

func generate_core(core_radius):
	var polygon = PackedVector2Array()
	var uv = PackedVector2Array()
	
	var resolution = 2 ** round(log(celestial.radius * 1.8) / log(2))
	var center = Vector2(resolution * 0.5, resolution * 0.5)
	
	for i in celestial.tiles.size():
		var angle = lerp(0.0, TAU, i / float(celestial.tiles.size()))
		polygon.append(Vector2.from_angle(angle) * core_radius)
		uv.append(Vector2.from_angle(angle) * resolution * 0.5 + center)
		
	core.polygon = polygon
	core.uv = uv
	
	core.texture = core.texture.duplicate()
	var texture = core.texture
	
	texture.diffuse_texture = texture.diffuse_texture.duplicate()
	var diffuse = core.texture.diffuse_texture
	diffuse.width = resolution
	diffuse.height = resolution
	
	diffuse.color_ramp = celestial.color_ramp
	
	diffuse.noise = diffuse.noise.duplicate()
	var noise = diffuse.noise
	noise.frequency = celestial.noise_frequency * core_radius / resolution
	noise.noise_type = celestial.noise_type
	diffuse.noise = noise

func generate_water(outer_radius, inner_radius):
	var polygons = []
	var vertices = PackedVector2Array()
	var colors = PackedColorArray()
	var uv = PackedVector2Array()
	var water_size = 1.0 / float(WATER_RESOLUTION)
	
	for i in celestial.tiles.size() * WATER_RESOLUTION:
		var p = float(i) * water_size
		var dir = Vector2.from_angle(p * celestial.tile_curvature)
		var u_start = p * 32
		
		vertices.append(dir * outer_radius)
		colors.append(Color(Color.WHITE, 0.6))
		uv.append(Vector2(u_start, 0))
		
		vertices.append(dir * inner_radius)
		colors.append(Color(Color.WHITE, 1))
		uv.append(Vector2(u_start, 32))
	
	var vert_count = vertices.size()
	for i in celestial.tiles.size() * WATER_RESOLUTION:
		var index = i * 2
		polygons.push_back(PackedInt32Array([index + 0, index + 1, (index + 2) % vert_count]))
		polygons.push_back(PackedInt32Array([index + 1, (index + 2) % vert_count, (index + 3) % vert_count]))
	
	water.polygons = polygons
	water.polygon = vertices
	water.vertex_colors = colors
	water.uv = uv
	
	water.material.set_shader_parameter("wave_frequency", celestial.tiles.size() / 4.0)

func generator_occluder(occluder_radius):
	var polygon = PackedVector2Array()
	
	for i in celestial.tiles.size():
		var angle = i * celestial.tile_curvature
		polygon.append(Vector2.from_angle(angle) * occluder_radius)
	
	var occluder_polygon = OccluderPolygon2D.new()
	occluder_polygon.polygon = polygon
	occluder_polygon.cull_mode = OccluderPolygon2D.CULL_CLOCKWISE
	occluder.occluder = occluder_polygon

func generate_surfaces():
	for celestial_tile in celestial_tiles:
		celestial_tile.queue_free()
	
	celestial_tiles = []
	
	for i in celestial.tiles.size():
		var tile = celestial.tiles[i]
		var celestial_tile = tile_scene.instantiate()
		
		celestial_tile.tile = tile
		celestial_tile.rotation = i * celestial.tile_curvature
		
		celestial_tiles.append(celestial_tile)
		add_child(celestial_tile)

func generate_gravity():
	var mass = PI * celestial.radius * celestial.radius * celestial.density
	gravity.gravity = mass * GRAVITATIONAL_CONSTANT
	gravity_shape.shape = CircleShape2D.new()
	gravity_shape.shape.radius = sqrt(gravity.gravity / 0.0003)

func sample(test_position: Vector2, surface_offset: float = 0) -> CelestialSample:
	var up = (test_position - global_position).normalized()
	var distance = test_position.distance_to(global_position)
	var tile_angle_offset = TAU * -0.25 + celestial.tile_curvature * 0.5 - rotation
	var tile_angle = up.rotated(tile_angle_offset).angle() + TAU * 0.5
	
	var tile_index = tile_angle / TAU * celestial.tiles.size()
	var tile_subposition = fposmod(tile_index, 1)
	tile_index = int(tile_index)
	
	var tile_left = celestial.tiles[posmod(tile_index - 1, celestial.tiles.size())]
	var tile = celestial.tiles[posmod(tile_index, celestial.tiles.size())]
	var tile_right = celestial.tiles[posmod(tile_index + 1, celestial.tiles.size())]
	
	var surface_depth = tile.outer_radius + surface_offset
	
	var info = CelestialSample.new()
	info.up = up
	info.surface_position = up * surface_depth
	info.surface_depth = surface_depth
	info.core_distance = distance
	info.surface_distance = distance - surface_depth
	info.tile_subposition = tile_subposition
	info.tile_left = tile_left
	info.tile = tile
	info.tile_right = tile_right
	
	return info
