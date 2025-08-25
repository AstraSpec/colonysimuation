class_name CellDef

var tiles :Array = []

var region :int = -1
var chunk :Vector2i = Vector2i(-1, -1)

static var terrain :int = 0
static var floor :int = 1
static var wall :int = 2
static var object :int = 3

static func get_tile_layers() -> Array:
	return ["terrain", "floor", "wall", "object"]
