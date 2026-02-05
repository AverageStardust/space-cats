extends Control
class_name ItemDisplay

const TEXTURE_SIZE = Vector2(16, 16)
const DURABILITY_GRADIENT = preload("res://source/utility/durabilityGradient.tres")

@onready var item_texture = $ItemTexture
@onready var shadow_texture = $ItemShadow
@onready var item_counter = $Label
@onready var durability_meter = $DurabilityMeter

@export var slot: InventorySlot: set = set_slot
@export var tooltips := true

var shadow_item_id := "": set = set_shadow_item_id
var texture: AtlasTexture

func _ready():
	texture = item_texture.texture
	shadow_texture.texture = texture

func set_slot(value):
	if slot: slot.disconnect("changed", update_slot)
	slot = value
	slot.connect("changed", update_slot)
	update_slot()

func set_shadow_item_id(value):
	shadow_item_id = value
	update_slot()

func set_shadow(color, value):
	shadow_texture.material = shadow_texture.material.duplicate()
	shadow_texture.material.set_shader_parameter("shadow_color", color)
	shadow_texture.material.set_shader_parameter("shadow_mix", value)

func update_slot():
	if not is_node_ready(): await ready
	
	visible = true
	item_texture.visible = true
	item_counter.text = ""
	
	if not slot.is_empty():
		
		var texture_offset = ResourceManager.get_item(slot.item_id).texture_offset
		texture.region.position = TEXTURE_SIZE * Vector2(texture_offset)
		
		if slot.amount > 1:
			item_counter.text = str(slot.amount)
		
		durability_meter.visible = slot.durability < 1.0
		durability_meter.color = DURABILITY_GRADIENT.sample(slot.durability)
		durability_meter.size.x = 1 + roundi(slot.durability * 15.0)
	elif shadow_item_id != "":
		var texture_offset = ResourceManager.get_item(shadow_item_id).texture_offset
		texture.region.position = TEXTURE_SIZE * Vector2(texture_offset)
		item_texture.visible = false
		durability_meter.visible = false
	else:
		visible = false


func _on_mouse_entered():
	if tooltips:
		InputManager.get_tooltip().set_slot(slot)


func _on_mouse_exited():
	if tooltips:
		InputManager.dismiss_tooltip()
