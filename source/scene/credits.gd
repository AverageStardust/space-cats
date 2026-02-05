extends Node

func _ready():
	$TexturedPanel/VBoxContainer/Back.grab_focus()
	$TexturedPanel/VBoxContainer/RichTextLabel.meta_clicked.connect(on_meta_clicked)

func on_meta_clicked(meta):
	meta = str(meta)
	if meta.begins_with("http"):
		OS.shell_open(meta)
	elif meta.begins_with("res"):
		GlobalManager.licence_text = FileAccess.get_file_as_string(meta)
		SceneManager.open_scene("licence")

func _on_back_pressed():
	SceneManager.open_previous_scene()
