extends EntityScene

@onready var dialogue_box = $DialogueBox
@onready var radio_sound = $RadioSound

func _ready():
	dialogue_box.dialogue_changed.connect(on_dialogue_changed)

func on_dialogue_changed(dialogue):
	if dialogue != null:
		radio_sound.play()
