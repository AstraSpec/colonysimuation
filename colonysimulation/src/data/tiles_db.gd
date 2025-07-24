extends DbManager

const Z_INDEX_TYPE :Dictionary = {"terrain":0, "wall":1, "object":2}

func _init() -> void:
	load_db("res://data/tiles/")

func get_z_index(element :Dictionary) -> int:
	return Z_INDEX_TYPE[element["type"]]
