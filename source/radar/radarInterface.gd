extends SubViewportContainer

@onready var world: World = SceneManager.get_current_scene("world")

@onready var radar = $SubViewport/Radar
@onready var label = $SubViewport/Label

var ship: ShipBody

func _ready():
	world.save_changed.connect(on_save_changed)
	
func on_save_changed(_save):
	ship = world.ship
	radar.ship = ship
	radar.celestials = world.home.get_system_bodies()

func _process(_delta):
	var lines = []
	
	append_situation(lines)
	if lines.size() <= 1:
		lines.append("")
		append_readings(lines)
	
	label.text = "\n".join(lines)

func append_situation(lines):
	if ship.is_landed():
		lines.append("[color=GREEN]   LANDED[/color]")
	elif ship.is_near_autopilot():
		lines.append("[color=RED]  AUTOPILOT[/color]")
		lines.append("")
		lines.append("  RETURNING")
		lines.append("   TO SITE")
	else:
		lines.append("[color=YELLOW]   FLYING[/color]")

func append_readings(lines):
	lines.append("Speed: %2dm/s" % [ship.velocity.length() * 4.0])
	lines.append("")
	lines.append("Fuel:   %s" % [ship.ship.get_fuel_percent()])
