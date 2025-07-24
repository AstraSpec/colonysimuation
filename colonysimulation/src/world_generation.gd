extends Node2D

@onready var MapNoise :FastNoiseLite = preload("res://assets/noise/map.tres")

@onready var TerrainTexture :CompressedTexture2D = preload("res://assets/tiles/terrain.png")
@onready var WallTexture :CompressedTexture2D = preload("res://assets/tiles/walls.png")
@export var Tilemap :FastTileMap

const WORLD_SIZE :int = 250
const TILE_SIZE :int = 16

func generate_world() -> void:
	Tilemap.clear_cells()
	
	var dirtTerrain :Dictionary = TilesDb.get_data("dirt_terrain")
	var dz :int = TilesDb.get_z_index(dirtTerrain)
	
	var wallsPos :Array = []
	for i in WORLD_SIZE ** 2:
		var cellPos := Vector2i(i / WORLD_SIZE, i % WORLD_SIZE)
		Tilemap.set_cell(cellPos, Vector2i(cellPos.x % 3, cellPos.y % 3), TILE_SIZE, TerrainTexture, dz)
		
		var noise = MapNoise.get_noise_2d(cellPos.x, cellPos.y)
		if noise > 0.3:
			wallsPos.append(cellPos)
	
	var stoneWall :Dictionary = TilesDb.get_data("stone_wall")
	var sz :int = TilesDb.get_z_index(stoneWall)
	
	Tilemap.set_cells_autotile(wallsPos, stoneWall["atlas"], TILE_SIZE, WallTexture, sz)
	
