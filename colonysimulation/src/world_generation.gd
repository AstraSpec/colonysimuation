extends Node2D

@onready var MapNoise :FastNoiseLite = preload("res://assets/noise/map.tres")
@export var WallLayer :TileMapLayer
@export var TerrainLayer :TileMapLayer

const WORLD_SIZE :int = 100
const TILE_SIZE :int = 16

func generate_world() -> void:
	WallLayer.clear()
	TerrainLayer.clear()
	
	var wallsPos :Array = []
	for i in WORLD_SIZE ** 2:
		var cellPos := Vector2i(i / WORLD_SIZE, i % WORLD_SIZE)
		
		var noise = MapNoise.get_noise_2d(cellPos.x, cellPos.y)
		if noise > 0.3:
			wallsPos.append(cellPos)
	
	var dirtTerrain :Dictionary = TilesDb.get_data("dirt_terrain")
	var dirtAtlas :Vector2i = Vector2(dirtTerrain["atlas"][0], dirtTerrain["atlas"][1])
	
	for x in WORLD_SIZE / 3:
		for y in WORLD_SIZE / 3:
			TerrainLayer.set_cell(Vector2(x * 3, y * 3), 0, dirtAtlas)
	
	var stoneWall :Dictionary = TilesDb.get_data("stone_wall")
	WallLayer.set_cells_terrain_connect(wallsPos, 0, stoneWall["terrain"])
	
