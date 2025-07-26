extends Node2D

@onready var MapNoise :FastNoiseLite = preload("res://assets/noise/map.tres")
@onready var TreeNoise :FastNoiseLite = preload("res://assets/noise/trees.tres")
@onready var GrassNoise :FastNoiseLite = preload("res://assets/noise/grass.tres")

@export var Tilemap :FastTileMap

const WORLD_SIZE :int = 250
const TILE_SIZE :int = 16

func generate_world() -> void:
	Tilemap.clear_cells()
	
	var terrainPos :Array = []
	var wallsPos :Array = []
	var trees1Pos :Array = []
	var trees2Pos :Array = []
	var trees3Pos :Array = []
	var grassPos :Array = []
	var tallGrassPos :Array = []
	
	for i in WORLD_SIZE ** 2:
		var cellPos := Vector2i(i / WORLD_SIZE, i % WORLD_SIZE)
		
		if cellPos.x % 3 == 0 and cellPos.y % 3 == 0:
			terrainPos.append(cellPos)
		
		if MapNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.3:
			wallsPos.append(cellPos)
		
		elif TreeNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.25:
			if randf() > 0.33: trees1Pos.append(cellPos)
			elif randf() > 0.5: trees2Pos.append(cellPos)
			else: trees3Pos.append(cellPos)
		
		# Generate grass and tall grass
		elif GrassNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.1:
			if GrassNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.25:
				tallGrassPos.append(cellPos)
			else:
				grassPos.append(cellPos)
	
	var dirtTerrain :Dictionary = TilesDb.get_config("stone_terrain")
	Tilemap.set_cells(terrainPos, dirtTerrain)
	
	var stoneWall :Dictionary = TilesDb.get_config("stone_wall")
	Tilemap.set_cells_autotile(wallsPos, stoneWall)
	
	var tree1Object :Dictionary = TilesDb.get_config("tree1")
	Tilemap.set_cells(trees1Pos, tree1Object)
	var tree2Object :Dictionary = TilesDb.get_config("tree2")
	Tilemap.set_cells(trees2Pos, tree2Object)
	var tree3Object :Dictionary = TilesDb.get_config("tree3")
	Tilemap.set_cells(trees3Pos, tree3Object)
	
	# Place grass and tall grass
	var grassObject :Dictionary = TilesDb.get_config("grass")
	Tilemap.set_cells(grassPos, grassObject)
	var tallGrassObject :Dictionary = TilesDb.get_config("tall_grass")
	Tilemap.set_cells(tallGrassPos, tallGrassObject)
	
	
