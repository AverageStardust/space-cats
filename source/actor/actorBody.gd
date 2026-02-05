extends CharacterBody2D
class_name ActorBody

signal changed_surface(surface: Node2D)
signal reached_point
signal collided(velocity: Vector2, shape: Object)

@onready var world: World = SceneManager.get_current_scene("world")

@export var actor: Actor: set = set_actor

var surface: Node2D = null: set = set_surface
var target_point: Node2D = null
var noclip = false

func _physics_process(_delta):
	if surface is CelestialBody:
		walk_on_ground(surface)
	elif surface == null:
		float_in_space()
	
	actor.position = global_position
	actor.velocity = velocity
	actor.rotation = global_rotation

func walk_on_ground(celestial: CelestialBody):
	var sample = celestial.sample(global_position, actor.surface_offset)
	var movement
	if target_point == null:
		movement = get_input_movement()
	else:
		movement = get_point_movement(target_point)
	
	if actor.space_movment:
		if get_local_gravity().length() < -movement.y * actor.acceleration:
			surface = null
			return
	
	if actor.ground_movment:
		var input_axis = movement.length() * clamp(movement.x * 2, -1, 1)
		var strength =  actor.stop_strength if input_axis == 0 else  actor.walk_strength
		var speed = speed_at_sample(sample)
		actor.surface_velocity = move_toward(actor.surface_velocity, input_axis * speed, strength)
	
	var correction_step = collide_with_tiles(sample)
	
	var change_in_surface_angle = (actor.surface_velocity + correction_step) / sample.surface_depth
	var new_surface_position = sample.surface_position.rotated(change_in_surface_angle)
	global_position = celestial.global_position + new_surface_position
	rotation = lerp_angle(rotation, get_standing_direction(), actor.alignment_strength)

func speed_at_sample(sample: CelestialSample):
	var max_speed = 0
	
	if not sample.tile.is_land() or noclip:
		max_speed = max(max_speed, actor.max_water_speed)
	if not sample.tile.is_water() or noclip:
		max_speed = max(max_speed, actor.max_speed)
	
	return max_speed

func collide_with_tiles(sample: CelestialSample):
	var correction_step = 0;
	
	var water_move = actor.max_water_speed > 0 or noclip
	var land_move = actor.max_speed > 0 or noclip
	
	if sample.tile_subposition < actor.tile_width - 0.001:
		var is_water = sample.tile_left.is_water()
		var is_land = sample.tile_left.is_land()
		if (is_water and not water_move) or (is_land and not land_move):
			actor.surface_velocity = max(0, actor.surface_velocity)
			correction_step = (actor.tile_width - sample.tile_subposition) * 32.0
	
	if sample.tile_subposition > 1.001 - actor.tile_width:
		var is_water = sample.tile_right.is_water()
		var is_land = sample.tile_right.is_land()
		if (is_water and not water_move) or (is_land and not land_move):
			actor.surface_velocity = min(actor.surface_velocity, 0)
			correction_step = (1.0 - actor.tile_width - sample.tile_subposition) * 32.0
	
	return correction_step
	

func float_in_space():
	if actor.space_movment:
		velocity += get_input_movement().rotated(rotation) * actor.acceleration

	velocity += get_local_gravity()
	velocity *= 1.0 - actor.space_dampening
	
	actor.angular_velocity = lerp(actor.angular_velocity, get_input_rotation() * actor.max_angular_velocity, 0.05)
	rotation += actor.angular_velocity
	
	move_step(velocity)

func move_step(motion):
	var collision = move_and_collide(motion)
	if collision == null: return
	on_collision(collision)

func on_collision(collision):
	var collider = collision.get_collider()
	
	if collider is CelestialBody:
		var relative_velocity = collision.get_collider_velocity() - velocity
		collided.emit(relative_velocity, collision.get_local_shape())
			
		if actor.ground_placement:
				surface = collider

func set_actor(value):
	actor = value
	teleport_to(actor.position)
	velocity = actor.velocity
	global_rotation = actor.rotation

func teleport_to(target_position):
	global_position = target_position
	surface = null

func set_surface(value: Node2D):
	surface = value
	changed_surface.emit(surface)
	
	if not is_node_ready(): await ready
	if surface == null:
		actor.angular_velocity = 0.0
		reparent(world)
	else:
		velocity = Vector2.ZERO
		actor.surface_velocity = 0.0
		reparent(surface)

func get_point_movement(point: Node2D):
	var differance = point.global_position - global_position
	var angle = Vector2.from_angle(global_rotation + TAU * 0.25).angle_to(differance)
	var speed = clamp(differance.length() / 25.0, 0.0, 0.5)
	if speed < 0.1:
		reached_point.emit()
		return Vector2.ZERO
	elif angle < 0.0:
		return Vector2.RIGHT * speed
	elif angle > 0.0:
		return Vector2.LEFT * speed

func get_local_gravity():
	return PhysicsServer2D.body_get_direct_state(get_rid()).total_gravity

func get_input_movement():
	return Vector2.ZERO

func get_input_rotation():
	return 0

func get_standing_direction():
	if not (surface is CelestialBody): return null
	var sample = surface.sample(global_position, actor.surface_offset)
	return sample.up.angle() + TAU * 0.25
