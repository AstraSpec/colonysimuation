extends Node2D

@onready var MapNoise :FastNoiseLite = preload("res://assets/noise/map.tres")
@onready var TreeNoise :FastNoiseLite = preload("res://assets/noise/trees.tres")

@export var Tilemap :FastTileMap

const WORLD_SIZE :int = 250
const TILE_SIZE :int = 16

func generate_world() -> void:
	Tilemap.clear_cells()
	
	var terrainPos :Array = []
	var wallsPos :Array = []
	var treesPos :Array = []
	
	for i in WORLD_SIZE ** 2:
		var cellPos := Vector2i(i / WORLD_SIZE, i % WORLD_SIZE)
		
		if cellPos.x % 3 == 0 and cellPos.y % 3 == 0:
			terrainPos.append(cellPos)
		
		if MapNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.3:
			wallsPos.append(cellPos)
		
		elif TreeNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.25:
			treesPos.append(cellPos)
	
	var dirtTerrain :Dictionary = TilesDb.get_config("stone_terrain")
	Tilemap.set_cells(terrainPos, dirtTerrain)
	
	var stoneWall :Dictionary = TilesDb.get_config("stone_wall")
	Tilemap.set_cells_autotile(wallsPos, stoneWall)
	
	var treeObject :Dictionary = TilesDb.get_config("tree")
	Tilemap.set_cells(treesPos, treeObject)
	
	
