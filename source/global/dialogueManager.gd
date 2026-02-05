extends Node

const DIALOGUE_CLASS = preload("res://source/dialogue/dialogue.gd")
const DIALOGUE_IDS = ["smokey", "eclipse"]

var dialouge_cache = {}
var done_ready = false

func _ready():
	for id in DIALOGUE_IDS:
		load_dialouge(id)
	
	done_ready = true

func open_dialogue(id: String, path: String = "start") -> Dialogue:
	var dialogue = load_dialouge(id)
	dialogue.open(path)
	return dialogue

func load_dialouge(id: String):
	if dialouge_cache.has(id):
		return dialouge_cache.get(id)
	
	if done_ready:
		push_warning("Failed to load dialogue early %s.ink.json" % [id])
	
	var dialouge = DIALOGUE_CLASS.new(id)
	dialouge_cache[id] = dialouge
	add_child(dialouge)
	return dialouge

func parse_text(text: String):
	if not text.contains("<"): 
		return text
	
	var result = ""
	var i = 0
	var in_code = false
	var code_content = ""
	var length = text.length()
	
	while i < length:
		var text_char = text[i]
		i += 1
		
		if not in_code and text_char == "\\" and i + 1 < length:
			var next_text_char = text[i + 1]
			if next_text_char == "<" or next_text_char == ">":
				result += next_text_char
				i += 1 # skip escape code
				continue
		
		if text_char == "<" and not in_code:
			in_code = true
			continue
		elif text_char == ">" and in_code:
			in_code = false
			result += parse_code(code_content)
			code_content = ""
			continue
		
		if in_code:
			code_content += text_char
		else:
			result += text_char
	
	return result

func parse_code(content: String):
	content = content.strip_edges()
	
	if content.begins_with("item="):
		var item_id = content.substr(5)
		var item = ResourceManager.get_item(item_id)
		if item != null:
			return "[color=\"red\"]%s[/color]" % [item.name]
	
	if content.begins_with("item_tag="):
		var item_tag = content.substr(9).to_int()
		var tag_name = InventoryItem.ItemTag.keys()[item_tag]
		return "[color=\"red\"]Any %s[/color]" % [tag_name]
	
	
	if content.begins_with("name="):
		return "[color=\"cyan\"]%s[/color]" % [content.substr(5)]
	
	return "[%s]" % [content]
