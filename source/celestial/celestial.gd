extends Resource
class_name Celestial 

@export_category("Planet")
@export var density = 1.0
@export var color_ramp: Gradient
@export var noise_frequency := 0.09
@export var noise_type: FastNoiseLite.NoiseType
@export var tiles: Array[Tile]: set = set_tiles
@export var has_waves: bool
@export var music_regions: Array[MusicRegion] = []

@export_category("Orbit")
@export var orbital_velocity: float
@export var orbital_radius: float
@export var orbital_phase: float
@export var orbital_time: float
@export var satellites := {}

var radius: float
var tile_curvature: float
var mass: float

func copy_likeness(celestial : Celestial):
	density = celestial.density
	color_ramp = celestial.color_ramp
	noise_frequency = celestial.noise_frequency
	noise_type = celestial.noise_type
	has_waves = celestial.has_waves
	music_regions = celestial.music_regions
	
	orbital_velocity = celestial.orbital_velocity
	orbital_radius = celestial.orbital_radius
	orbital_phase = celestial.orbital_phase

func reset_position():
	orbital_time = 0.0
	for satellite in satellites.values():
		satellite.reset_position()

func resize_tiles(tile_count):
	tiles.resize(tile_count)
	
	for i in tiles.size():
		if tiles[i] == null:
			tiles[i] = Tile.new()
			
	update()

func set_tiles(value):
	if value.size() == 0:
		resize_tiles(8)
	else:
		tiles = value
	
	update()

func update():
	radius = tiles.size() * 32 / TAU
	tile_curvature = TAU / tiles.size()
	mass = PI * radius * radius * density
	
	for i in tiles.size():
		if tiles[i] == null:
			tiles[i] = Tile.new()
		tiles[i].curvature = tile_curvature
		tiles[i].outer_radius = radius
		tiles[i].inner_radius = radius - 32
	
	emit_changed()
