extends Node

@onready var fullscreen_button: CheckButton = $TexturedPanel/VBoxContainer/General/Fullscreen
@onready var master_slider: Slider = $TexturedPanel/VBoxContainer/Sound/Master
@onready var dialogue_slider: Slider = $TexturedPanel/VBoxContainer/Sound/Dialogue
@onready var interface_slider: Slider = $TexturedPanel/VBoxContainer/Sound/Interface
@onready var music_slider: Slider = $TexturedPanel/VBoxContainer/Sound/Music
@onready var world_slider: Slider = $TexturedPanel/VBoxContainer/Sound/World
@onready var alert: ConfirmationDialog = $Alert
@onready var settings := SettingsManager.settings

func _ready():
	$TexturedPanel/VBoxContainer/Back.grab_focus()
	SettingsManager.settings_changed.connect(update_settings)
	update_settings()
	
	SoundManager.set_music_volume([-2, -2, -2, -2])
	SoundManager.set_music_speed(1)

func update_settings():
	fullscreen_button.button_pressed = settings.fullscreen
	master_slider.value = settings.get_volume_level("Master")
	dialogue_slider.value = settings.get_volume_level("Dialogue")
	interface_slider.value = settings.get_volume_level("Interface")
	music_slider.value = settings.get_volume_level("Music")
	world_slider.value = settings.get_volume_level("World")

func _on_fullscreen_toggled(toggled_on):
	settings.fullscreen = toggled_on

func _on_reset_save_pressed():
	alert.dialog_text = "Delete all progress?"
	alert.popup_centered()
	alert.confirmed.get_connections()
	if not alert.confirmed.is_connected(SaveManager.load_init):
		alert.confirmed.connect(SaveManager.load_init)

func _on_back_pressed():
	SceneManager.open_previous_scene()

func _on_master_value_changed(value):
	settings.set_volume_level("Master", value)

func _on_dialogue_value_changed(value):
	settings.set_volume_level("Dialogue", value)

func _on_interface_value_changed(value):
	settings.set_volume_level("Interface", value)

func _on_music_value_changed(value):
	settings.set_volume_level("Music", value)

func _on_world_value_changed(value):
	settings.set_volume_level("World", value)
