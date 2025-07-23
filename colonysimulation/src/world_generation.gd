extends Node2D

@onready var MapNoise :FastNoiseLite = preload("res://assets/noise/map.tres")

@onready var TerrainTexture :CompressedTexture2D = preload("res://assets/tiles/terrain.png")
@onready var WallTexture :CompressedTexture2D = preload("res://assets/tiles/walls.png")
@export var TerrainLayer :FastTileMap
@export var WallLayer :FastTileMap

const WORLD_SIZE :int = 250
const TILE_SIZE :int = 16

func generate_world() -> void:
	WallLayer.clear_tiles()
	TerrainLayer.clear_tiles()
	
	var wallsPos :Array = []
	for i in WORLD_SIZE ** 2:
		var cellPos := Vector2i(i / WORLD_SIZE, i % WORLD_SIZE)
		TerrainLayer.set_tile(cellPos, Vector2i(cellPos.x % 3, cellPos.y % 3), TILE_SIZE, TerrainTexture)
		
		var noise = MapNoise.get_noise_2d(cellPos.x, cellPos.y)
		if noise > 0.3:
			wallsPos.append(cellPos)
	
	var stoneWall :Dictionary = TilesDb.get_data("stone_wall")
	var timer1 = Time.get_ticks_usec()
	WallLayer.set_cells_autotile(wallsPos, 0, TILE_SIZE, WallTexture)
	var timer2 = Time.get_ticks_usec()
	
	print("Time taken: ", str(timer2-timer1))
	
