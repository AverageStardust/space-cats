extends HBoxContainer
class_name DialogueInterface

signal choice_made(index: int)
signal continued

const CHAR_WIDTH = 46
const CHARS_PER_SECOND = 45
const CHOICE_SEPERATOR = "  "
const PORTRAIT_SIZE = 64
const PORTRAIT_POSITIONS = {
	"clementine": Vector2(0, 0),
	"smokey": Vector2(0, 1),
	"eclipse": Vector2(0, 2),
	"radio": Vector2(0, 3)
}

@onready var portrait_rect = $PortraitSlot/Portrait
@onready var name_label = $CenterContainer/Background/VBoxContainer/NameLabel
@onready var text_label = $CenterContainer/Background/VBoxContainer/RichTextLabel
@onready var continue_button = $CenterContainer/Background/VBoxContainer/RichTextLabel/ContinueButton
@onready var meow_sound = $MeowSound

var displayed_chars := 0.0
var portrait := "": set = set_portrait

func _process(delta):
	if is_text_scrolling():
		var new_chars = delta * CHARS_PER_SECOND
		displayed_chars = min(displayed_chars + new_chars, text_label.text.length())
		if not meow_sound.playing:
			meow_sound.play_random()
	
	if text_label.text.length() >= 0:
		text_label.visible_ratio = displayed_chars / text_label.text.length()
	else:
		text_label.visible_ratio = 0

func set_portrait(value):
	portrait = value
	
	var portrait_position = PORTRAIT_POSITIONS.get(portrait)
	if portrait_position == null:
		push_error("Failed to find portrait %s" % [portrait])
		return
	
	portrait_rect.texture.region.position = portrait_position * PORTRAIT_SIZE

func add_text(text: String):
	if not text.ends_with("\n"):
		text += "\n"
	text_label.text += text

func set_tags(tags: Array):
	for tag in tags:
		if tag == "wait":
			await prompt_continue()
			clear_text()
		else:
			portrait = tag

func add_choices(choices: Array):
	var choices_text = CHOICE_SEPERATOR
	var line_length = 0
	
	for i in choices.size():
		var text = "(%s)" % [choices[i].strip_edges()]
		var link = "[color=pink][url=%s]%s[/url][/color]" % [i, text]
		
		if i == 0:
			choices_text += link
			line_length += text.length()
		else:
			if line_length + CHOICE_SEPERATOR.length() + text.length() >= CHAR_WIDTH:
				choices_text += "\n"
				line_length = 0
			choices_text += CHOICE_SEPERATOR + link
			line_length += CHOICE_SEPERATOR.length() + text.length()
	
	add_text(choices_text)

func _on_text_label_meta_clicked(meta):
	choice_made.emit(int(meta))

func prompt_continue():
	(func (): continue_button.visible = true).call_deferred()
	return await continued

func _on_continue_button_pressed():
	if is_text_scrolling():
		skip_text_scroll()
		return
	
	continued.emit()
	continue_button.visible = false

func is_text_scrolling():
	return displayed_chars < text_label.text.length()

func skip_text_scroll():
	displayed_chars = text_label.text.length()

func clear_text():
	text_label.text = ""
	displayed_chars = 0
