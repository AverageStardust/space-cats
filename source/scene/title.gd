extends Node

@onready var play_button = $Panel/VBoxContainer/VBoxContainer/Play
@onready var version_label = $Panel/VBoxContainer/VersionLabel

func _ready():
	play_button.grab_focus()
	play_button.text = "Continue" if SaveManager.state.played else "Start"
	var version = ProjectSettings.get_setting("application/config/version")
	version_label.text = "v%s" % [version]
	
	SoundManager.set_music_volume([0, -60, -60, 0])
	SoundManager.set_music_speed(1)

func _on_play_pressed():
	SceneManager.open_scene("world") 

func _on_options_pressed():
	SceneManager.open_scene("options")

func _on_credits_pressed():
	SceneManager.open_scene("credits")

func _on_exit_pressed():
	await get_tree().create_timer(0.08).timeout
	SceneManager.save_and_quit()
