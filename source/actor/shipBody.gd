extends ActorBody
class_name ShipBody

const DOWN_THRUST_STRENGTH = 0.3
const OPEN_SPACE_THRESHOLD = 8e-4
const RECALL_THRESHOLD = 3.0
const RECALL_ANGLE = TAU / -8
const RECALL_ALTITUDE = 60
const RECALL_VELOCITY = -0.4
const ENGINE_FUEL_RATE = 1.4
const THRUSTER_FUEL_RATE = 0.3
const REPAIR_ITEM_ID = "mechanism"
const BOUNCE_STENGTH = 2.2
const THRUST_SOUND_DELAY = 0.15

@onready var sprite = $Sprite2D
@onready var warning_light = $PointLight2D
@onready var interaction_box: InteractionBox = $InteractionBox
@onready var up_particles = $UpEngineParticles
@onready var down_particles = $DownEngineParticles
@onready var top_left_particles = $TopLeftThrusterParticles
@onready var top_right_particles = $TopRightThrusterParticles
@onready var bottom_left_particles = $BottomLeftThrusterParticles
@onready var bottom_right_particles = $BottomRightThrusterParticles
@onready var thrust_sound = $ThrustSound
@onready var impact_sound = $ImpactSound

@export var ship: Ship: set = set_ship

var player: PlayerBody
var origin_body: CelestialBody
var hotbar_volume: InventoryVolume
var lost_time := 0.0
var auto_pilot := false
var thrust_sound_timeout := 0.0
var age := 0.0

func _ready():
	interaction_box.interacted.connect(on_interaction)
	world.save_changed.connect(on_save_changed)
	collided.connect(on_collided)

func on_save_changed(_save):
	player = world.player
	hotbar_volume = world.hotbar.volume
	origin_body = world.home
	
	player.camera.faded_out.connect(on_faded_out)
	player.camera.faded_in.connect(on_faded_in)
	hotbar_volume.focused_changed.connect(update_interaction)
	hotbar_volume.slots_changed.connect(update_interaction)
	update_interaction()
	
	if ship.boarded:
		board()
		player.camera.jump_to_zoom()

func _process(delta):
	age += delta
	
	if is_near_autopilot():
		warning_light.visible = fmod(lost_time, 0.5) > 0.25
	thrust_sound_timeout -= delta

func _physics_process(delta):
	super._physics_process(delta)
	update_interaction()
	
	if surface is CelestialBody:
		interact_with_celestial(surface)
	
	warning_light.visible = false
	
	var fuel_usage = 0.0
	fuel_usage += get_input_movement().length() * ENGINE_FUEL_RATE
	fuel_usage += abs(get_input_rotation()) * THRUSTER_FUEL_RATE
	ship.current_fuel = max(0, ship.current_fuel - fuel_usage * delta)
		
	var is_stranded = ship.current_fuel == 0
	var in_deep_space = get_local_gravity().length() < OPEN_SPACE_THRESHOLD and not is_landed()
	if in_deep_space or is_stranded:
		lost_time += delta
	else:
		lost_time = max(0, lost_time - delta)

	if lost_time > RECALL_THRESHOLD:
		if not auto_pilot:
			player.camera.fade_out()
		auto_pilot = true


func on_collided(relative_velocity, shape):
	var speed = relative_velocity.length()
	if shape.name.contains("Leg"):
		speed *= 0.5
	if speed > 1.5 and age > 0.1:
		impact_sound.play_random()
		impact_sound.volume_db = min(speed * 2.5, 25.0) - 9.0

func interact_with_celestial(celestial: CelestialBody):
	var sample = celestial.sample(global_position, actor.surface_offset)
	if sample.tile.is_water() or sample.tile_left.is_water() or sample.tile_right.is_water():
		surface = null
		velocity += sample.up * BOUNCE_STENGTH

func on_faded_in():
	if not auto_pilot: return
	
	auto_pilot = false

func on_faded_out():
	if not auto_pilot: return
	
	var recall_direction = Vector2.from_angle(RECALL_ANGLE)
	var recall_distance = origin_body.celestial.radius + RECALL_ALTITUDE
	var recall_position = origin_body.global_position + recall_direction * recall_distance
	
	global_position = recall_position
	global_rotation = RECALL_ANGLE + TAU * 0.25
	velocity = recall_direction * RECALL_VELOCITY
	
	lost_time = 0

func update_interaction():
	if ship.is_repaired() and is_landed():
		interaction_box.interaction = "board_ship"
		interaction_box.enabled = true
	elif is_holding_mechanism() and is_landed():
		interaction_box.interaction = "repair_ship"
		interaction_box.enabled = true
	else:
		interaction_box.enabled = false

func is_holding_mechanism():
	var slot = hotbar_volume.get_focused()
	return slot != null and slot.item_id == REPAIR_ITEM_ID

func use_hotbar_item():
	var slot = hotbar_volume.get_focused()
	assert(slot.remove(1, REPAIR_ITEM_ID))

func on_interaction():
	if not ship.is_repaired():
		use_hotbar_item()
		ship.repairs += 1
		return
	
	ship.boarded = not ship.boarded
	
	if ship.boarded:
		board()
	else:
		unboard()

func set_ship(value):
	if ship: ship.changed.disconnect(update_sprite)
	
	ship = value
	actor = ship.actor
	
	if not is_node_ready(): await ready
	ship.changed.connect(update_sprite)
	update_sprite()
	
	if not world.is_node_ready(): await world.ready
	
func update_sprite():
	sprite.frame = ship.repairs

func board():
	player.camera.target_zoom = 0.5
	player.lock_focus({ interaction_box.action: interaction_box})
	player.surface = self
	player.position = Vector2(0, -32)
	player.rotation = 0
	player.sprite.visible = false
	world.radar_panel.visible = true
	world.hotbar_panel.visible = false
	world.recipe_button.visible = false

func unboard():
	player.camera.target_zoom = 1
	player.unlock_focus()
	player.position = Vector2(0, -4)
	player.surface = null
	player.sprite.visible = true
	world.radar_panel.visible = false
	world.hotbar_panel.visible = true
	world.recipe_button.visible = true

func get_input_movement():
	var y = player.get_input_movement().y
	if auto_pilot: 
		y = 0.0
	
	if y > 0.0: # thrusting down
		if is_landed():
			y = 0.0
		else:
			y *= DOWN_THRUST_STRENGTH
	
	if not ship.boarded or ship.current_fuel == 0.0: 
		y = 0.0
	
	if y != 0.0:
		if y > 0.0:
			thrust_sound.volume_db = -16.0
		else:
			thrust_sound.volume_db = -8.0
		
		if not thrust_sound.playing or thrust_sound_timeout <= 0.0:
			thrust_sound.play()
			thrust_sound_timeout = THRUST_SOUND_DELAY
	
	up_particles.emitting = y < 0.0
	down_particles.emitting = y > 0.0
	
	return Vector2(0, y)

func get_input_rotation():
	var torque = player.get_input_movement().x
	
	if auto_pilot: torque = 0
	
	if is_landed() or not ship.boarded or ship.current_fuel == 0.0:
		torque = 0.0
	
	top_left_particles.emitting = torque < 0
	bottom_right_particles.emitting = torque < 0
	
	top_right_particles.emitting = torque > 0
	bottom_left_particles.emitting = torque > 0
	
	return torque

func is_landed():
	return surface is CelestialBody or surface is LandingPad

func is_near_autopilot():
	return lost_time > 0.05 or auto_pilot
