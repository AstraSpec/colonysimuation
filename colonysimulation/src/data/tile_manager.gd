extends DbManager

var textures :Dictionary

var tileDb :Dictionary

var TILE_LAYERS :Array = CellDef.get_tile_layers()

func _init() -> void:
	load_db("res://data/tiles/")
	_init_textures()
	_init_tiledata()
	
	data.clear()

func _init_tiledata() -> void:
	for element :Dictionary in data:
		var tile := TileDef.new()
		tile.id = element.id
		tile.name = element.name
		tile.type = element.type
		tile.texture = get_texture(element["texture"])
		tile.atlas = get_vector2(element, "atlas", tile)
		tile.size = get_vector2(element, "size", tile)
		tile.offset = get_vector2(element, "offset", tile)
		tile.z_index = get_z_index(element["type"])
		tile.flags = element.get("flags", [])
		
		tileDb[tile.id] = tile

func _init_textures() -> void:
	for element :Dictionary in data:
		var dataTexture = element.get("texture")
		if dataTexture:
			textures[dataTexture] = load("res://assets/tiles/" + dataTexture)

func get_vector2(element :Dictionary, key :String, tile :TileDef) -> Vector2i:
	return Vector2i(element[key][0], element[key][1]) if element.has(key) else tile.get(key)

func get_texture(texture :String) -> CompressedTexture2D:
	return textures[texture]

func get_z_index(type :String) -> int:
	return TILE_LAYERS.find(type)
