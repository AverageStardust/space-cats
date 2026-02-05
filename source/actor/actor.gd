extends Resource
class_name Actor

@export_subgroup("Physics")
@export var position = Vector2.ZERO
@export var velocity = Vector2.ZERO
@export var rotation = 0
@export var surface_velocity: float = 0
@export var angular_velocity: float = 0

@export_subgroup("Ground")
@export var ground_placement = true
@export var ground_movment = false
@export var tile_width = 0.25
@export var surface_offset = -6.0
@export var max_speed: float
@export var max_water_speed: float  = 0
@export var walk_strength: float
@export var stop_strength: float
@export var alignment_strength: float = 0.25

@export_subgroup("Space")
@export var space_movment = false
@export var acceleration: float
@export var max_angular_velocity: float
@export var space_dampening: float
