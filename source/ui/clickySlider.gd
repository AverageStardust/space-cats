extends HSlider

func _ready():
	value_changed.connect(play_click)
	drag_ended.connect(play_click)

func play_click(_argumenta):
	SoundManager.play_sound("slider")
