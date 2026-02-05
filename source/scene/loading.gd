extends Control

func _ready():
	call_deferred("load")

func load():
	SettingsManager.load_or_init()
	SaveManager.load_or_init()
	SceneManager.open_scene("title")
	
	SoundManager.set_music_volume([0, -60, -60, 0])
	SoundManager.set_music_speed(1)
	SoundManager.skip_music_fade()
	SoundManager.start_music()
