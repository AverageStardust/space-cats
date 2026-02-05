extends Resource
class_name Recipe

@export var item_ids: Array[String] = []
@export var item_tags: Array[InventoryItem.ItemTag] = []
@export var result_id := ""

func get_ingredient_codes():
	var ingredients = []
	
	for i in size():
		if item_ids.size() <= i or item_ids[i] == "":
			ingredients.append("<item_tag=%s>" %  item_tags[i])
		else:
			ingredients.append("<item=%s>" % [item_ids[i]])
	
	return ingredients

func craftable(save: SaveGame):
	for i in size():
		if item_ids.size() <= i or item_ids[i] == "":
			if not save.is_discovered(&"item_tag", item_tags[i]): return false
		else:
			if not save.is_discovered(&"item", item_ids[i]): return false

	return true

func match_recipe(ingredients: Array[String]) -> bool:
	if ingredients.size() != self.size():
		return false
	
	ingredients = ingredients.duplicate()
	
	for i in self.size():
		var matched_ingredient := -1
		if item_ids.size() <= i or item_ids[i] == "":
			matched_ingredient = match_item_tag(ingredients, item_tags[i])
		else:
			matched_ingredient = match_item_id(ingredients, item_ids[i])
		
		if matched_ingredient == -1:
			return false
		
		ingredients.remove_at(matched_ingredient)
	
	return true

func match_item_id(ingredients: Array[String], item_id: String) -> int:
	return ingredients.find(item_id)

func match_item_tag(ingredients: Array[String], item_tag: InventoryItem.ItemTag) -> int:
	for i in ingredients.size():
		var item = ResourceManager.get_item(ingredients[i])
		if item.tags.has(item_tag):
			return i
	return -1

func size():
	return max(item_ids.size(), item_tags.size())
