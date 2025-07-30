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
	
	var tilePos :Dictionary = TilesDb.get_worldspawn_tiles()
	var terrainPos :Dictionary = tilePos["terrain"]
	var floorPos :Dictionary = tilePos["floor"]
	var wallPos :Dictionary = tilePos["wall"]
	var objectPos :Dictionary = tilePos["object"]
	
	for i in WORLD_SIZE ** 2:
		var cellPos := Vector2i(i / WORLD_SIZE, i % WORLD_SIZE)
		
		var map_noise = MapNoise.get_noise_2d(cellPos.x, cellPos.y)
		var wall_noise = WallNoise.get_noise_2d(cellPos.x, cellPos.y)
		var grass_noise = GrassNoise.get_noise_2d(cellPos.x, cellPos.y)
		var tree_noise = TreeNoise.get_noise_2d(cellPos.x, cellPos.y)
		var tall_grass_noise = TallGrassNoise.get_noise_2d(cellPos.x, cellPos.y)
		
		if MapNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.27:
			if WallNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.0:
				terrainPos["stone_terrain"].append(cellPos)
			else:
				terrainPos["dirt_terrain"].append(cellPos)
		else:
			terrainPos["dirt_terrain"].append(cellPos)
		
		if MapNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.3:
			if WallNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.0:
				wallPos["stone_wall"].append(cellPos)
			else:
				wallPos["mud_wall"].append(cellPos)
		else:
			if GrassNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.4:
				floorPos["grass"].append(cellPos)
			
			if TreeNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.25:
				if randf() > 0.33: objectPos["tree1"].append(cellPos)
				elif randf() > 0.5: objectPos["tree2"].append(cellPos)
				else: objectPos["tree3"].append(cellPos)
			
			elif TallGrassNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.555:
				if randf() > 0.05:
					objectPos["tall_grass2"].append(cellPos)
				else:
					if randf() > 0.5:
						objectPos["tall_grass3"].append(cellPos)
					else:
						objectPos["tall_grass4"].append(cellPos)
			elif TallGrassNoise.get_noise_2d(cellPos.x, cellPos.y) > 0.45:
				objectPos["tall_grass1"].append(cellPos)
	
	for tile in terrainPos: Tilemap.set_terrain_cells(terrainPos[tile], TilesDb.get_config(tile))
	for tile in floorPos: Tilemap.set_cells_autotile(floorPos[tile], TilesDb.get_config(tile), floorPos[tile])
	for tile in objectPos: Tilemap.set_cells(objectPos[tile], TilesDb.get_config(tile))
	
	var totalPos :Array = []
	for tile in wallPos: totalPos.append_array(wallPos[tile])
	for tile in wallPos: Tilemap.set_cells_autotile(wallPos[tile], TilesDb.get_config(tile), totalPos)
	
	
