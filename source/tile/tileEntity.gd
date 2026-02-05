extends Resource
class_name TileEntity

@export var texture_offset: Vector2i
@export var has_sprite: bool = true
@export var scene_id: String
@export var scene_options: Resource = null
@export var inital_state: Resource = null
@export var water_platform: bool = false
@export var height_offset: int = -6
@export var item: String = ""
