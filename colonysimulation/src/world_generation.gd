extends Node2D

@onready var ElevationNoise :FastNoiseLite = preload("res://assets/noise/elevation.tres")
@onready var GeologyNoise :FastNoiseLite = preload("res://assets/noise/geology.tres")
@onready var TreeNoise :FastNoiseLite = preload("res://assets/noise/trees.tres")
@onready var GrassNoise :FastNoiseLite = preload("res://assets/noise/grass.tres")
@onready var TallGrassNoise :FastNoiseLite = preload("res://assets/noise/tall_grass.tres")

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
		process_tile(cellPos, tilePos)
	
	for tile in terrainPos: Tilemap.set_terrain_cells(terrainPos[tile], TilesDb.get_config(tile))
	for tile in floorPos: Tilemap.set_cells_autotile(floorPos[tile], TilesDb.get_config(tile), floorPos[tile])
	for tile in objectPos: Tilemap.set_cells(objectPos[tile], TilesDb.get_config(tile))
	
	var totalPos :Array = []
	for tile in wallPos: totalPos.append_array(wallPos[tile])
	for tile in wallPos: Tilemap.set_cells_autotile(wallPos[tile], TilesDb.get_config(tile), totalPos)
	
func process_tile(cellPos :Vector2, tilePos :Dictionary) -> void:
	var noise = {
		"elevation": ElevationNoise.get_noise_2d(cellPos.x, cellPos.y),
		"geology": GeologyNoise.get_noise_2d(cellPos.x, cellPos.y),
		"grass": GrassNoise.get_noise_2d(cellPos.x, cellPos.y),
		"tallGrass": TallGrassNoise.get_noise_2d(cellPos.x, cellPos.y),
		"tree": TreeNoise.get_noise_2d(cellPos.x, cellPos.y),
	}
	
	process_terrain(cellPos, tilePos["terrain"], noise)
	
	var has_wall = process_wall(cellPos, tilePos["wall"], noise)
	
	if not has_wall:
		process_vegetation(cellPos, tilePos, noise)

func process_terrain(cellPos :Vector2, terrainPos :Dictionary, noise :Dictionary) -> void:
	if noise.elevation > 0.27 && noise.geology > 0.0:
		terrainPos["stone_terrain"].append(cellPos)
	else:
		terrainPos["dirt_terrain"].append(cellPos)

func process_wall(cellPos :Vector2, wallPos :Dictionary, noise :Dictionary) -> bool:
	if noise.elevation > 0.3:
		if noise.geology > 0.0:
			wallPos["stone_wall"].append(cellPos)
		else:
			wallPos["mud_wall"].append(cellPos)
		
		return true
	return false

func process_vegetation(cellPos :Vector2, tilePos :Dictionary, noise :Dictionary) -> void:
	var floorPos = tilePos["floor"]
	var objectPos = tilePos["object"]
	
	if noise.grass > 0.4:
		floorPos["grass"].append(cellPos)
			
	if noise.tree > 0.25:
		if randf() > 0.33: objectPos["tree1"].append(cellPos)
		elif randf() > 0.5: objectPos["tree2"].append(cellPos)
		else: objectPos["tree3"].append(cellPos)
	
	elif noise.tallGrass > 0.555:
		if randf() > 0.05:
			objectPos["tall_grass2"].append(cellPos)
		else:
			if randf() > 0.5:
				objectPos["tall_grass3"].append(cellPos)
			else:
				objectPos["tall_grass4"].append(cellPos)
	elif noise.tallGrass > 0.45:
		objectPos["tall_grass1"].append(cellPos)
