extends Node

func _ready():
	$TexturedPanel/VBoxContainer/Back.grab_focus()
	$TexturedPanel/VBoxContainer/RichTextLabel.text = GlobalManager.licence_text

func _on_back_pressed():
	SceneManager.open_previous_scene()
