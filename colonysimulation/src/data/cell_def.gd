class_name CellDef

var tiles :Array = []

var item :ItemDef = null
var quantity :int = 0

var region :int = -1
var chunk :Vector2i = Vector2i(-1, -1)

static var terrain :int = 0
static var floor :int = 1
static var object :int = 2

static func get_tile_layers() -> Array:
	return ["terrain", "floor", "object"]
