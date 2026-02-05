extends Sprite2D

const RADAR_COLOR = "d8fab6"
const RADAR_CENTER = Vector2(-54, 2)
const RADAR_SCALE = 9e-3
const RADAR_FREQUENCEY = 0.5
const RADAR_PULSE_LENGTH = 0.3

@onready var pulse = $Pulse

var ship: ShipBody
var celestials: Array[CelestialBody] = []
var draw_delay = 0.0

func _process(delta):
	draw_delay += delta
	
	if draw_delay > RADAR_FREQUENCEY - RADAR_PULSE_LENGTH:
		pulse.texture.gradient.colors[0].a = 0
		pulse.texture.gradient.colors[1].a = 0.45
		pulse.texture.gradient.colors[2].a = 0
		var progress = (draw_delay - RADAR_FREQUENCEY + RADAR_PULSE_LENGTH) / RADAR_PULSE_LENGTH
		pulse.texture.gradient.offsets[0] = clamp(progress - 0.06, 0, 1)
		pulse.texture.gradient.offsets[1] = clamp(progress, 0.001, 0.999)
		pulse.texture.gradient.offsets[2] = clamp(progress + 0.06, 0, 1)
	else:
		pulse.texture.gradient.colors[1].a = 0.0
	
	if draw_delay > RADAR_FREQUENCEY:
		queue_redraw()
		draw_delay -= RADAR_FREQUENCEY

func _draw():
	for celestial in celestials:
		var direction = celestial.global_position - ship.global_position
		direction = direction.rotated(-ship.global_rotation - 0.015)
		direction *= RADAR_SCALE
		var distance = direction.length()
		
		if distance > 38.0: continue
		
		var radius = max(1.0, celestial.celestial.radius * RADAR_SCALE - 0.5)
		var alpha = 20.0 / max(20.0, distance)
		
		draw_circle(round(RADAR_CENTER + direction), radius, Color(RADAR_COLOR, alpha))
