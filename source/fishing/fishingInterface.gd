extends Control
class_name FishingInterface

static var SPEAR_STRENGTH_TIMES = [1.0, 0.8, 0.6]

var FISHING_PLANE_SCENE = ResourceManager.get_packed_scene("fishing/fishingPlane.tscn")
var THROWN_SPEAR_SCENE = ResourceManager.get_packed_scene("fishing/thrownSpear.tscn")
var FISH_SHADOW_SCENE = ResourceManager.get_packed_scene("fishing/fishShadow.tscn")
const MAX_FISH_COUNT := 3
const MIN_SPAWN_DELAY := 1.0
const MAX_SPAWN_DELAY := 15.0

@onready var world: World = SceneManager.get_current_scene("world")
@onready var sub_viewport = $SubViewport
@onready var holding_spear = $HoldingSpear

var hotbar_volume: InventoryVolume
var spear_in_air := false: set = set_spear_in_air
var fish_types: Array
var fishes: Array[FishShadow] = []
var spawn_timeout := 0.0

func _ready():
	fish_types = ResourceManager.get_resources("fish", "fish").values()
	connect_hotbar_volume.call_deferred()
	create_planes()

func _process(delta):
	if fishes.size() == 0:
		spawn_timeout -= delta * 2.0
	else:
		spawn_timeout -= delta
	
	if spawn_timeout > 0: return
	if not get_parent().visible: return
	
	if fishes.size() < MAX_FISH_COUNT:
		spawn_timeout = randf_range(MIN_SPAWN_DELAY, MAX_SPAWN_DELAY)
		
		spawn_fish()

func spawn_fish():
	var fish = FISH_SHADOW_SCENE.instantiate()
	var valid_fish_types = fish_types.filter(func(fish_type):
		return fish_type.spawn_threshold <= world.save.fish_caught)
		
	fish.tree_exiting.connect(func(): fishes.remove_at(fishes.find(fish)))
	fish.fish = valid_fish_types.pick_random()
	fish.create_path(sub_viewport.size)
	fishes.append(fish)
	
	sub_viewport.add_child(fish)

func connect_hotbar_volume():
	hotbar_volume = world.hotbar.volume
	hotbar_volume.focused_changed.connect(update_spear)
	hotbar_volume.slots_changed.connect(update_spear)
	update_spear()

func create_planes():
	for i in 12:
		var plane = FISHING_PLANE_SCENE.instantiate()
		plane.position.x = randi_range(-128, -256)
		plane.position.y = randi_range(-46, -50) + i * 32
		sub_viewport.add_child(plane)

func set_spear_in_air(value):
	spear_in_air = value
	update_spear()

func update_spear():
	holding_spear.visible = get_spear_strength() > 0 and not spear_in_air
	if holding_spear.visible:
		holding_spear.material.set_shader_parameter("spear_color", get_spear_color())

func _on_throw_outline_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			throw_spear(get_local_mouse_position())

func throw_spear(target: Vector2):
	if spear_in_air: return
	
	var strength = get_spear_strength()
	if strength == 0: return
	
	var spear = THROWN_SPEAR_SCENE.instantiate()
	spear.set_spear_color(get_spear_color())
	spear.set_path(Vector2(400, target.y), target, SPEAR_STRENGTH_TIMES[strength - 1])
	
	spear.hit.connect(on_spear_hit)
	spear_in_air = true
	
	hotbar_volume.get_focused().damage()
	sub_viewport.add_child(spear)

func on_spear_hit(spear, point):
	var hit_fish = false
	
	for fish in fishes:
		if fish.intersects(point):
			fish.catch()
			hit_fish = true
	
	spear_in_air = false
	
	if not hit_fish:
		spear.queue_free()

func get_spear_strength():
	var slot = hotbar_volume.get_focused()
	if slot == null or slot.item_id == "": return 0
	
	var item: InventoryItem = ResourceManager.get_item(slot.item_id)
	if item.tool_type != InventoryItem.ToolType.Spear: return 0
	
	return item.tool_strength

func get_spear_color():
	var slot = hotbar_volume.get_focused()
	match slot.item_id:
		"flintSpear":
			return Color("#6a556d")
		"ironSpear":
			return Color("#b3c2cb")
		"copperSpear":
			return Color("#c0690c")
		_:
			return Color.MAGENTA
