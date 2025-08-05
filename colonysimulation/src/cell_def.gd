class_name CellDef

var tiles :Dictionary = {}

var region :int = -1
var chunk :Vector2i = Vector2i(-1, -1)

static func get_tile_layers() -> Array:
	return ["terrain", "floor", "wall", "object"]
