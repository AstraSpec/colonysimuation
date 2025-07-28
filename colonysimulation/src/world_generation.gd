extends Node2D

@onready var MapNoise :FastNoiseLite = preload("res://assets/noise/map.tres")
@onready var TreeNoise :FastNoiseLite = preload("res://assets/noise/trees.tres")
@onready var GrassNoise :FastNoiseLite = preload("res://assets/noise/grass.tres")
@onready var TallGrassNoise :FastNoiseLite = preload("res://assets/noise/tall_grass.tres")
@onready var WallNoise :FastNoiseLite = preload("res://assets/noise/walls.tres")

@export var Tilemap :FastTileMap

const WORLD_SIZE :int = 250
const TILE_SIZE :int = 16

func generate_world() -> void:
	Tilemap.clear_cells()
	
	var tilePos :Dictionary = {}
	var autotilePos :Dictionary = {}
	var grassPos :Dictionary = {}
	var terrainPos :Dictionary = {}
	
	var dirtTerrain :Dictionary = TilesDb.get_config("dirt_terrain")
	var stoneTerrain :Dictionary = TilesDb.get_config("stone_terrain")
	var stoneWall :Dictionary = TilesDb.get_config("stone_wall")
	var mudWall :Dictionary = TilesDb.get_config("mud_wall")
	var tree1 :Dictionary = TilesDb.get_config("tree1")
	var tree2 :Dictionary = TilesDb.get_config("tree2")
	var tree3 :Dictionary = TilesDb.get_config("tree3")
	var grass :Dictionary = TilesDb.get_config("grass")
	var tallGrass1 :Dictionary = TilesDb.get_config("tall_grass1")
	var tallGrass2 :Dictionary = TilesDb.get_config("tall_grass2")
	var tallGrass3 :Dictionary = TilesDb.get_config("tall_grass3")
	var tallGrass4 :Dictionary = TilesDb.get_config("tall_grass4")
	
	# Initialize arrays for each tile type
	terrainPos[dirtTerrain] = []
	terrainPos[stoneTerrain] = []
	tilePos[stoneWall] = []
	tilePos[mudWall] = []
	tilePos[tree1] = []
	tilePos[tree2] = []
	tilePos[tree3] = []
	tilePos[tallGrass1] = []
	tilePos[tallGrass2] = []
	tilePos[tallGrass3] = []
	tilePos[tallGrass4] = []
	autotilePos[stoneWall] = []
	autotilePos[mudWall] = []
	grassPos[grass] = []
	
	for i in WORLD_SIZE ** 2:
		var cellPos := Vector2i(i / WORLD_SIZE, i % WORLD_SIZE)
		
		if MapNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.27:
			if WallNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.0:
				terrainPos[stoneTerrain].append(cellPos)
			else:
				terrainPos[dirtTerrain].append(cellPos)
		else:
			terrainPos[dirtTerrain].append(cellPos)
			#else:
			#	autotilePos[mudTerrain].append(cellPos)
		
		if MapNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.3:
			if WallNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.0:
				autotilePos[stoneWall].append(cellPos)
			else:
				autotilePos[mudWall].append(cellPos)
		else:
			if GrassNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.4:
				grassPos[grass].append(cellPos)
			
			if TreeNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.25:
				if randf() > 0.33: tilePos[tree1].append(cellPos)
				elif randf() > 0.5: tilePos[tree2].append(cellPos)
				else: tilePos[tree3].append(cellPos)
			
			elif TallGrassNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.555:
				if randf() > 0.05:
					tilePos[tallGrass2].append(cellPos)
				else:
					if randf() > 0.5:
						tilePos[tallGrass3].append(cellPos)
					else:
						tilePos[tallGrass4].append(cellPos)
			elif TallGrassNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.45:
				tilePos[tallGrass1].append(cellPos)
				
	for t in tilePos: Tilemap.set_cells(tilePos[t], t)
	for t in terrainPos: Tilemap.set_terrain_cells(terrainPos[t], t)
	
	var totalPos :Array = []
	for t in autotilePos: totalPos.append_array(autotilePos[t])
	for t in autotilePos: Tilemap.set_cells_autotile(autotilePos[t], t, totalPos)
	for t in grassPos: Tilemap.set_cells_autotile(grassPos[t], t, grassPos[t])
	
	
