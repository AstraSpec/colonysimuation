extends DbManager

var textures :Dictionary

var itemDb :Dictionary

func _init() -> void:
	load_db("res://data/items/")
	_init_textures()
	_init_itemdata()
	
	data.clear()

func _init_itemdata() -> void:
	for element :Dictionary in data:
		var item := ItemDef.new()
		item.id = element.id
		item.name = element.name
		item.texture = get_texture(element["texture"])
		
		if element.has("atlas"):
			item.atlas = get_vector2(element, "atlas", item)
		
		itemDb[item.id] = item

func _init_textures() -> void:
	for element :Dictionary in data:
		var dataTexture = element.get("texture")
		if dataTexture:
			textures[dataTexture] = load("res://assets/items/" + dataTexture)

func get_vector2(element :Dictionary, key :String, item :ItemDef) -> Vector2i:
	return Vector2i(element[key][0], element[key][1]) if element.has(key) else item.get(key)

func get_texture(texture :String) -> CompressedTexture2D:
	return textures[texture]
