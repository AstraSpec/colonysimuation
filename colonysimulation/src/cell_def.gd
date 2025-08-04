class_name CellDef

var terrain :TileDef = TileManager.emptyTile
var floor :TileDef = TileManager.emptyTile
var wall :TileDef = TileManager.emptyTile
var object :TileDef = TileManager.emptyTile
var region :int = -1
var chunk :Vector2i = Vector2i(-1, -1)

static func get_tile_layers() -> Array:
	return ["terrain", "floor", "wall", "object"]
