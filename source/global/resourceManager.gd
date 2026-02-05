extends Node

const RESOURCE_FOLDER = "res://resources/"
const PACKED_SCENE_FOLDER = "res://source/"
const RESOURCE_EXTENSION = "tres"
const SCENE_EXTENSION = "tscn"

# FUCK FUCK FUCK FUCK FUCK
# I HATE YOU GODOT
# JUST LET ME PRELOAD MY FUCKING SCENE FROM MULTIPLE SCRIPTS
# YOU BITCH

var packed_scene_cache = {
	"ui/itemHolder.tscn": preload("res://source/ui/itemHolder.tscn"),
	"ui/tooltip.tscn": preload("res://source/ui/tooltip.tscn"),
	"inventory/droppedItemBody.tscn": preload("res://source/inventory/droppedItemBody.tscn"),
	"utility/durabilityGradient.tres": preload("res://source/utility/durabilityGradient.tres"),
	"tile/celestialTile.tscn": preload("res://source/tile/celestialTile.tscn"),
	"inventory/slotInterface.tscn": preload("res://source/inventory/slotInterface.tscn"),
	"fishing/fishingPlane.tscn": preload("res://source/fishing/fishingPlane.tscn"),
	"fishing/thrownSpear.tscn": preload("res://source/fishing/thrownSpear.tscn"),
	"fishing/fishShadow.tscn": preload("res://source/fishing/fishShadow.tscn"),
	"crafting/recipePage.tscn": preload("res://source/crafting/recipePage.tscn"),
	"crafting/recipeDisplay.tscn": preload("res://source/crafting/recipeDisplay.tscn"),
	"actor/raftBody.tscn": preload("res://source/actor/raftBody.tscn"),
}

var resource_cache = {}
var tagged_items = {}
var items_catorgized = false

func get_items_by_tag(tag: InventoryItem.ItemTag):
	catorgize_items()
	if not tagged_items.has(tag): return []
	return tagged_items[tag]

func catorgize_items():
	if items_catorgized: return
	var items = get_resources("item", "InventoryItem")
	for item_id in items.keys():
		catorgize_item(item_id, items[item_id])
	
	items_catorgized = true

func catorgize_item(item_id: String, item: InventoryItem):
	for tag in item.tags:
		if tagged_items.has(tag):
			tagged_items[tag].append(item_id)
		else:
			tagged_items[tag] = [item_id]

func get_resources(folder: String, hint_type := "", id_prefix := "") -> Dictionary:
	var list = list_resources(folder)
	var resources := {}
	
	for id in list:
		var resource = get_resource("%s/%s.%s" % [folder, id, RESOURCE_EXTENSION], hint_type)
		if resource != null:
			resources[id_prefix + id] = resource
	
	return resources

func list_resources(folder, prefix = "") -> PackedStringArray:
	var files = PackedStringArray()
	var dir = DirAccess.open(RESOURCE_FOLDER + folder)
	
	for subDir in dir.get_directories():
		files.append_array(list_resources(folder + "/" + subDir, prefix + subDir + "/"))
		
	for file in dir.get_files():
		files.append(prefix + file.split(".")[0])
	
	return files

func get_surface(id: String) -> TileSurface:
	return get_resource("surface/%s.%s" % [id, RESOURCE_EXTENSION], "TileSurface")

func get_entity(id: String) -> TileEntity:
	return get_resource("entity/%s.%s" % [id, RESOURCE_EXTENSION], "TileEntity")

func get_entity_scene(id: String) -> PackedScene:
	return get_resource("entityScene/%s.%s" % [id, SCENE_EXTENSION],  "PackedScene")
	
func get_item(id: String) -> InventoryItem:
	return get_resource("item/%s.%s" % [id, RESOURCE_EXTENSION], "InventoryItem")

func get_recipe(id: String) -> Recipe:
	return get_resource("recipe/%s.%s" % [id, RESOURCE_EXTENSION], "Recipe")

func get_resource(id: String, _hint_type = "") -> Resource:
	if not resource_cache.has(id):
		resource_cache[id] = load(RESOURCE_FOLDER + id)
		if resource_cache[id] == null:
			printerr("Failed to load resource %s" % [id])
	
	return resource_cache[id]

func get_packed_scene(id: String, _hint_type = "") -> PackedScene:
	if not packed_scene_cache.has(id):
		print("Missed packed_scene preload!")
		print("	\"%s\": preload(\"%s\")," % [id, PACKED_SCENE_FOLDER + id])
		
		packed_scene_cache[id] = load(PACKED_SCENE_FOLDER + id)
		if packed_scene_cache[id] == null:
			push_error("Failed to load packed scene %s" % [id])
	
	return packed_scene_cache[id]
