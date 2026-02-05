extends TextureRect
class_name RecipeIcon

const ICON_SIZE := 32

var recipe_folder: String: set = set_recipe_folder

func set_recipe_folder(folder):
	recipe_folder = folder
	texture.region.position.x = folder_to_position(recipe_folder)

func folder_to_position(folder: String) -> float:
	match folder:
		"assembly":
			return 0.0
		"campfire":
			return ICON_SIZE * 1.0
		"smelter":
			return ICON_SIZE * 2.0
		_:
			return 0.0
