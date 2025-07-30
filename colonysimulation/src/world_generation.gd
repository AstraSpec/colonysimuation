extends Node2D

@onready var ElevationNoise :FastNoiseLite = preload("res://assets/noise/elevation.tres")
@onready var GeologyNoise :FastNoiseLite = preload("res://assets/noise/geology.tres")
@onready var TreeNoise :FastNoiseLite = preload("res://assets/noise/trees.tres")
@onready var GrassNoise :FastNoiseLite = preload("res://assets/noise/grass.tres")
@onready var TallGrassNoise :FastNoiseLite = preload("res://assets/noise/tall_grass.tres")

@export var Tilemap :FastTileMap

const WORLD_SIZE :int = 250
const TILE_SIZE :int = 16

const TERRAIN_THRESHOLD :float = 0.27
const CLIFF_THRESHOLD :float = 0.3
const GRASS_THRESHOLD :float = 0.4
const TREE_THRESHOLD :float = 0.25
const TALL_GRASS_HIGH_THRESHOLD :float = 0.555
const TALL_GRASS_LOW_THRESHOLD :float = 0.45
const FLOWER_THRESHOLD :float = 0.05

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
	for tile in floorPos:
		Tilemap.set_cells_autotile(floorPos[tile], TilesDb.get_config(tile), floorPos[tile])
	for tile in objectPos: 
		Tilemap.set_cells(objectPos[tile], TilesDb.get_config(tile))
	
	var totalPos :Array = []
	for tile in wallPos: totalPos.append_array(wallPos[tile])
	for tile in wallPos: Tilemap.set_cells_autotile(wallPos[tile], TilesDb.get_config(tile), totalPos)
	
func process_tile(cellPos :Vector2, tilePos :Dictionary) -> void:
	var noise :Dictionary = {
		"elevation": ElevationNoise.get_noise_2d(cellPos.x, cellPos.y),
		"geology": GeologyNoise.get_noise_2d(cellPos.x, cellPos.y),
		"grass": GrassNoise.get_noise_2d(cellPos.x, cellPos.y),
		"tallGrass": TallGrassNoise.get_noise_2d(cellPos.x, cellPos.y),
		"tree": TreeNoise.get_noise_2d(cellPos.x, cellPos.y),
	}
	
	process_terrain(cellPos, tilePos["terrain"], noise)
	process_wall(cellPos, tilePos["wall"], noise)
	
	if noise.elevation <= TERRAIN_THRESHOLD:
		process_floor(cellPos, tilePos["floor"], noise)
		process_object(cellPos, tilePos["object"], noise)

func process_terrain(cellPos :Vector2, terrainPos :Dictionary, noise :Dictionary) -> void:
	if noise.elevation > TERRAIN_THRESHOLD && noise.geology > 0.0:
		terrainPos["stone_terrain"].append(cellPos)
	else:
		terrainPos["dirt_terrain"].append(cellPos)

func process_wall(cellPos :Vector2, wallPos :Dictionary, noise :Dictionary) -> void:
	if noise.elevation > CLIFF_THRESHOLD:
		var type :String = "stone_wall" if noise.geology > 0.0 else "mud_wall"
		wallPos[type].append(cellPos)

func process_floor(cellPos :Vector2, floorPos :Dictionary, noise :Dictionary) -> void:
	if noise.grass > GRASS_THRESHOLD:
		floorPos["grass"].append(cellPos)

func process_object(cellPos :Vector2, objectPos :Dictionary, noise :Dictionary) -> void:
	var vegetation :String = get_vegetation(cellPos, objectPos, noise)
	if vegetation != "":
		objectPos[vegetation].append(cellPos)

func get_vegetation(cellPos :Vector2, objectPos :Dictionary, noise :Dictionary) -> String:
	if noise.tree > TREE_THRESHOLD:
		var trees :Array = ["tree1", "tree2", "tree3"]
		trees.shuffle()
		return trees[0]
	
	elif noise.tallGrass > TALL_GRASS_HIGH_THRESHOLD:
		if randf() > FLOWER_THRESHOLD:
			return "tall_grass2"
		else:
			return "flower1" if randf() > 0.5 else "flower2"
	elif noise.tallGrass > TALL_GRASS_LOW_THRESHOLD:
		return "tall_grass1"
	
	return ""
