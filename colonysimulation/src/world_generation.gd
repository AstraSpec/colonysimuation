extends FastTileMap

@onready var Tiles :CompressedTexture2D = preload("res://assets/tiles.png")

const WORLD_SIZE :int = 256
const TILE_SIZE :int = 16

func generate_world() -> void:
	set_tile(Vector2(0, 0), 0, TILE_SIZE, Tiles)
