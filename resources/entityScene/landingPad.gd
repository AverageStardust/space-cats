extends EntityScene
class_name LandingPad

const LANDED_POSITION = Vector2(0, -10)

@onready var world: World = SceneManager.get_current_scene("world")
@onready var left_light = $LeftPointLight2D
@onready var right_light = $RightPointLight2D

var time := 0.0
var ship: ShipBody = null
var landing := false

func _process(delta):
	time += delta
	var illuminated = world.ship.ship.is_repaired() and fmod(time, 0.7) < 0.25
	left_light.visible = illuminated
	right_light.visible = illuminated

func _physics_process(delta):
	if ship == null: return
	
	if ship.get_input_movement().y < -0.5 and not landing:
		ship.position.y -= 0.3
		return
	
	if ship.position.y > 16:
		ship.position = LANDED_POSITION
		ship.global_rotation = global_rotation
	else:
		ship.position = ship.position.lerp(LANDED_POSITION, 0.05)
		ship.global_rotation = lerp(ship.global_rotation, global_rotation, 0.05)
	
	if ship.position.distance_to(LANDED_POSITION) < 2.0:
		ship.ship.refuel(delta)
		landing = false

func _on_landing_area_body_entered(body):
	if body is ShipBody:
		ship = body
		landing = true
		(func():
			if ship == null:
				landing = false
				return
			ship.surface = self).call_deferred()

func _on_landing_area_body_exited(body):
	if body is ShipBody and not landing:
		(func():
			if landing or ship == null: return
			ship.surface = null
			ship = null).call_deferred()
