extends DbManager

const Z_INDEX_TYPE :Dictionary = {"terrain":0, "floor":1, "wall":2, "object":3}
var textures :Dictionary = {}

func _init() -> void:
	load_db("res://data/tiles/")
	_init_textures()

func _init_textures() -> void:
	for element :Dictionary in data:
		var dataTexture = element.get("texture")
		if dataTexture:
			textures[dataTexture] = load("res://assets/tiles/" + dataTexture)

func get_config(id :String) -> Dictionary:
	var element :Dictionary = get_data(id)
	
	return {
		"atlas": TilesDb.get_vector2(element, "atlas", Vector2.ZERO),
		"texture": TilesDb.get_texture(element),
		"z_index": TilesDb.get_z_index(element),
		"offset": TilesDb.get_vector2(element, "offset", Vector2.ZERO),
		"size": TilesDb.get_vector2(element, "size", Vector2.ONE)
	}

func get_vector2(element :Dictionary, key :String, defVal :Vector2) -> Vector2:
	if element.has(key):
		return Vector2(element[key][0], element[key][1])
	return defVal

func get_texture(element :Dictionary) -> CompressedTexture2D:
	return textures[element["texture"]]

func get_z_index(element :Dictionary) -> int:
	return Z_INDEX_TYPE[element["type"]]
