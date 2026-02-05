extends ActorBody
class_name PlayerBody

signal focus_unlocked

const FORCE_LOCK_TIME = 0.5
const STEP_DELAY = 0.40

@onready var camera = $ShaderCamera
@onready var interaction_source = $InteractionSource
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine = $AnimationTree.get("parameters/playback")
@onready var item_root: Node2D = $Sprite2D/ItemRoot
@onready var item_display: ItemDisplay = $Sprite2D/ItemRoot/ItemDisplay
@onready var flower_root: Node2D = $Sprite2D/FlowerRoot
@onready var flower_sprite: Sprite2D = $Sprite2D/FlowerRoot/Flower
@onready var movement_tutorial = $MovementTutorial
@onready var pickup_sound = $PickupSound
@onready var drop_sound = $DropSound
@onready var step_sound = $StepSound
@onready var wave_sound = $WaveSound

@export var player: Player: set = set_player

var surface_brush = null
var entity_brush = null
var lock_movement := false
var force_lock_time := 0.0
var step_timeout := 0.0

func _ready():
	item_display.shadow_texture.visible = false

func _process(delta):
	control_sound()
	animate()
	
	step_timeout -= delta
	force_lock_time -= delta
	
	if Input.is_action_pressed("place_tile") and surface is CelestialBody:
		var sample = surface.sample(global_position)
		brush_tile(sample.tile)
	
	item_root.scale.x = -1 if sprite.flip_h else 1
	flower_root.scale.x = -1 if sprite.flip_h else 1
	
	update_hand()
	flower_sprite.visible = player.volume.contains_item("flowerCrown")

func control_sound():
	if surface is CelestialBody:
		var sample = surface.sample(global_position)
		
		if surface.celestial.has_waves:
			if not sample.tile.is_land() or not sample.tile_left.is_land() or not sample.tile_right.is_land():
				if not wave_sound.is_playing():
					wave_sound.play_random()
		
		for music_region in surface.celestial.music_regions:
			if music_region.contains_angle(sample.up.angle()):
				SoundManager.set_music_volume(music_region.volumes)
				break;
		SoundManager.set_music_speed(1)
	elif surface is ShipBody:
		SoundManager.set_music_volume([3, 8, 3, 3])
		SoundManager.set_music_speed(1.12)

func animate():
	if surface is ActorBody:
		if abs(surface.actor.surface_velocity) > 0.5:
			sprite.flip_h = surface.actor.surface_velocity > 0
	
	if abs(actor.surface_velocity) > 0.5:
		state_machine.travel("run")
		sprite.flip_h = actor.surface_velocity > 0
		if not step_sound.playing or step_timeout < 0.0:
			step_sound.play_random()
			step_timeout += STEP_DELAY
	else:
		if target_point != null:
			sprite.flip_h = angle_difference(target_point.global_rotation, global_rotation + TAU * 0.25) > 0.0
		
		if interaction_source.pressed:
			var box = interaction_source.focused_boxes.get("interact_1")
			if box != null:
				var dir = box.global_position - global_position
				sprite.flip_h = dir.rotated(-rotation).x > 0
				state_machine.travel("swing")
		else:
			state_machine.travel("idle")

func update_hand():
	var focused_slot: InventorySlot = player.volume.get_focused()
	if focused_slot == null or focused_slot.is_empty():
		item_display.slot.set_amount_item(0)
	else:
		item_display.slot.set_amount_item(1, focused_slot.item_id, focused_slot.max_durability)

func take_slot(slot: InventorySlot):
	if slot.is_empty(): return
	if player.volume.transfer(slot):
		pickup_sound.play()
	else:
		drop_slot(slot)

func drop_slot(slot: InventorySlot, idle_time = 1.5):
	if slot.is_empty(): return
	var drop_position = global_position
	drop_position += Vector2(randf_range(-8, 8), 11).rotated(global_rotation + PI)
	world.add_item(DroppedItem.new(slot, drop_position, idle_time))
	drop_sound.play()

func brush_tile(tile: Tile):
	if surface_brush != null and tile.surface_id != surface_brush: 
		tile.surface_id = surface_brush
	if entity_brush != null and tile.entity_id != entity_brush:
		tile.entity_id = entity_brush

func set_player(value):
	player = value
	actor = player.actor
	
	if not is_node_ready(): await ready
	movement_tutorial.player = player

func lock_focus(focused_boxes):
	lock_movement = true
	interaction_source.lock_focus(focused_boxes)
	force_lock_time = FORCE_LOCK_TIME

func unlock_focus():
	lock_movement = false
	interaction_source.unlock_focus()
	focus_unlocked.emit()

func get_input_movement():
	if not get_window().has_focus():
		return Vector2.ZERO
	
	var move_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if lock_movement and not (surface is ShipBody):
		if abs(move_vec.x) < 0.5 or force_lock_time > 0:
			return Vector2.ZERO
		else:
			unlock_focus()
	
	return move_vec

#func get_input_rotation():
	#var celestial = get_nearest_celestial()
	#if celestial == null: return 0
	#
	#var info = celestial.info_from(global_position)
	#var target_angle = info.up.angle() + TAU * 0.25
	#var full_strength_threshhold = 5 * space_max_rotation
	#return clamp(angle_difference(rotation, target_angle) / full_strength_threshhold, -1, 1)

#func get_nearest_celestial() -> Celestial:
	#var nearest_distance = INF
	#var nearest_celestial = null
	#
	#for celestial in camera.nearby_celestials.values():
		#var surface_distance = celestial.info_from(global_position).surface_distance
		#if surface_distance < nearest_distance:
			#nearest_distance = surface_distance
			#nearest_celestial = celestial
	#
	#return nearest_celestial
