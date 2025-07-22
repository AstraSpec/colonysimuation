extends FastTileMap

@onready var Tiles :CompressedTexture2D = preload("res://assets/tiles.png")

const WORLD_SIZE :int = 256
const TILE_SIZE :int = 16

func generate_world() -> void:
	var stoneWall :Dictionary = TilesDb.get_data("stone_wall")
	set_cells_autotile([Vector2(-1, -1), Vector2(0, -1), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0),Vector2(1, 1), Vector2(1, 2), Vector2(1, -1)], stoneWall["atlas"], TILE_SIZE, Tiles)
