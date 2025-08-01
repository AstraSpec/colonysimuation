class_name CellDef

var terrain :TileDef = TileManager.emptyTile
var floor :TileDef = TileManager.emptyTile
var wall :TileDef = TileManager.emptyTile
var object :TileDef = TileManager.emptyTile
var region :int

static func get_tile_layers() -> Array:
	return ["terrain", "floor", "wall", "object"]
