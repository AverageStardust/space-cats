extends Resource
class_name Player

@export var actor: Actor
@export var volume: InventoryVolume
@export var tutorials_done = {
	"move_left": false,
	"move_right": false
}

func reset():
	volume.empty()
	volume.slots[0].focused = true
	for key in tutorials_done.keys():
		tutorials_done[key] = false
	reset_position()

func reset_position():
	actor.position = Vector2(0, -100)
	actor.rotation = 0
