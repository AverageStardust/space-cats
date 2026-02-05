extends ActorBody
class_name RaftBody

func _ready():
	world.player.surface = self
	world.player.position = Vector2(0, -8)
	world.save.raft = actor

func destroy():
	world.save.raft = null
	world.player.surface = null
	queue_free()

func get_input_movement():
	return world.player.get_input_movement()
