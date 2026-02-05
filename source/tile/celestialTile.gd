extends Node2D
class_name CelestialTile

const TEXTURE_SIZE = Vector2(32, 32)

@onready var ground: Polygon2D = $Ground
@onready var entity_sprite: Sprite2D = $EntitySprite
@onready var entity_plot: EntityPlot = $EntityPlot

var tile: Tile: set = set_tile
var entity_node: EntityScene = null

func _ready():
	generate_ground()

func generate_ground():
	var curvature = tile.curvature
	var outer_radius = tile.outer_radius
	var inner_radius = max(0, tile.inner_radius)
	var mid_radius = lerp(tile.outer_radius, tile.inner_radius, 0.75)
	
	var polygons = []
	var vertices = PackedVector2Array()
	var colors = PackedColorArray()
	
	vertices.append(Vector2.from_angle(-0.5 * curvature - TAU * 0.25) * inner_radius)
	colors.append(Color.TRANSPARENT)
	
	vertices.append(Vector2.from_angle(-0.5 * curvature - TAU * 0.25) * mid_radius)
	colors.append(Color.WHITE)
	
	vertices.append(Vector2.from_angle(-0.5 * curvature - TAU * 0.25) * outer_radius)
	colors.append(Color.WHITE)
	
	vertices.append(Vector2.from_angle(0.5 * curvature - TAU * 0.25) * outer_radius)
	colors.append(Color.WHITE)
	
	vertices.append(Vector2.from_angle(0.5 * curvature - TAU * 0.25) * mid_radius)
	colors.append(Color.WHITE)
	
	vertices.append(Vector2.from_angle(0.5 * curvature - TAU * 0.25) * inner_radius)
	colors.append(Color.TRANSPARENT)
	
	polygons.push_back(PackedInt32Array([0, 1, 4]))
	polygons.push_back(PackedInt32Array([0, 4, 5]))
	polygons.push_back(PackedInt32Array([1, 2, 3]))
	polygons.push_back(PackedInt32Array([1, 3, 4]))
	
	ground.polygons = polygons
	ground.polygon = vertices
	ground.vertex_colors = colors
	
	entity_plot.position.y = -(tile.outer_radius - 6)

func set_tile(value: Tile):
	if tile: 
		tile.surface_changed.disconnect(update_surface)
		tile.entity_changed.disconnect(update_entity)
	tile = value
	tile.surface_changed.connect(update_surface)
	tile.entity_changed.connect(update_entity)
	update_tile()

func update_tile():
	if not is_node_ready(): await ready
	update_surface()
	update_entity()
	entity_plot.tile = tile

func update_surface():
	if not is_node_ready(): await ready
	
	var surface = ResourceManager.get_surface(tile.surface_id)
	var texture_offset = TEXTURE_SIZE * Vector2(surface.texture_offset)
	var uv = PackedVector2Array()
	
	uv.append(Vector2(0, 32) + texture_offset)
	uv.append(Vector2(0, 24) + texture_offset)
	uv.append(Vector2(0, 0) + texture_offset)
	uv.append(Vector2(32, 0) + texture_offset)
	uv.append(Vector2(32, 24) + texture_offset)
	uv.append(Vector2(32, 32) + texture_offset)
	
	ground.uv = uv

func update_entity():
	if not is_node_ready(): await ready
	
	entity_sprite.visible = false
	if entity_node != null: entity_node.queue_free()
	if tile.entity_id != "":
		init_entity()

func init_entity():
	var entity = ResourceManager.get_entity(tile.entity_id)
	
	set_entity_texture_offset(entity.texture_offset)
	entity_sprite.position.y = -(tile.outer_radius + 16 + entity.height_offset)
	entity_sprite.visible = entity.has_sprite
	
	if entity.scene_id != "":
		init_entity_scene(entity)

func init_entity_scene(entity: TileEntity):
	var scene = ResourceManager.get_entity_scene(entity.scene_id)
	entity_node = scene.instantiate()
	entity_node.changed_texture_offset.connect(set_entity_texture_offset)
	entity_node.celestial_tile = self
	
	if entity.scene_options != null:
		entity_node.options = entity.scene_options
	if tile.entity_state != null:
		entity_node.state = tile.entity_state
	
	entity_node.position.y = -(tile.outer_radius + entity.height_offset)
	entity_sprite.add_sibling(entity_node)

func set_entity_texture_offset(offset: Vector2i):
	entity_sprite.region_rect.position = TEXTURE_SIZE * Vector2(offset)
