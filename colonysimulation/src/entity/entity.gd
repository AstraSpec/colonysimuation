extends Node2D

static var TILE_SIZE :int = Constants.get_tile_size()

var cellPos :Vector2i = Vector2i.ZERO

func _process(_delta: float) -> void:
	position = cellPos * TILE_SIZE
	z_index = cellPos.y
