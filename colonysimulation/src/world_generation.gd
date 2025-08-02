extends Node2D

@onready var ElevationNoise :FastNoiseLite = preload("res://assets/noise/elevation.tres")
@onready var GeologyNoise :FastNoiseLite = preload("res://assets/noise/geology.tres")
@onready var TreeNoise :FastNoiseLite = preload("res://assets/noise/trees.tres")
@onready var GrassNoise :FastNoiseLite = preload("res://assets/noise/grass.tres")
@onready var TallGrassNoise :FastNoiseLite = preload("res://assets/noise/tall_grass.tres")

@export var Tilemap :FastTileMap
@export var Terrain :TextureRect

const WORLD_SIZE :int = 250
const TILE_SIZE :int = 16

const TERRAIN_THRESHOLD :float = 0.27
const CLIFF_THRESHOLD :float = 0.3
const GRASS_THRESHOLD :float = 0.4
const TREE_THRESHOLD :float = 0.25
const TALL_GRASS_HIGH_THRESHOLD :float = 0.555
const TALL_GRASS_LOW_THRESHOLD :float = 0.45
const FLOWER_THRESHOLD :float = 0.05

var mapData : Dictionary

func generate_world() -> void:
	Tilemap.clear_all()
	mapData.clear()
	
	for i in WORLD_SIZE ** 2:
		var cellPos := Vector2i(i / WORLD_SIZE, i % WORLD_SIZE)
		mapData[cellPos] = process_tile(cellPos)
	
	render_map()

func process_tile(cellPos :Vector2i) -> CellDef:
	var Cell := CellDef.new()
	
	var noise :Dictionary = {
		"elevation": ElevationNoise.get_noise_2d(cellPos.x, cellPos.y),
		"geology": GeologyNoise.get_noise_2d(cellPos.x, cellPos.y),
		"grass": GrassNoise.get_noise_2d(cellPos.x, cellPos.y),
		"tallGrass": TallGrassNoise.get_noise_2d(cellPos.x, cellPos.y),
		"tree": TreeNoise.get_noise_2d(cellPos.x, cellPos.y),
	}
	
	Cell.terrain = process_terrain(noise)
	Cell.wall = process_wall(noise)
	
	if noise.elevation <= TERRAIN_THRESHOLD:
		Cell.floor = process_floor(noise)
		Cell.object = process_object(noise)
	
	return Cell

func process_terrain(noise :Dictionary) -> TileDef:
	var type :String = "dirt_terrain"
	if noise.elevation > TERRAIN_THRESHOLD and noise.geology > 0.0:
		type = "stone_terrain"
	
	return TileManager.tileDb[type]

func process_wall(noise :Dictionary) -> TileDef:
	if noise.elevation > CLIFF_THRESHOLD:
		var type :String = "stone_wall" if noise.geology > 0.0 else "mud_wall"
		return TileManager.tileDb[type]
	return TileManager.emptyTile

func process_floor(noise :Dictionary) -> TileDef:
	if noise.grass > GRASS_THRESHOLD:
		return TileManager.tileDb["grass"]
	return TileManager.emptyTile

func process_object(noise :Dictionary) -> TileDef:
	var vegetation :String = get_vegetation(noise)
	if vegetation != "":
		return TileManager.tileDb[vegetation]
	return TileManager.emptyTile

func get_vegetation(noise :Dictionary) -> String:
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

func render_map() -> void:
	var cells :Dictionary = group_cells_by_tile()
	
	var terrainCells :Dictionary = cells["terrain"]
	var floorCells :Dictionary = cells["floor"]
	var wallCells :Dictionary = cells["wall"]
	var objectCells :Dictionary = cells["object"]
	
	for tile in terrainCells:
		Terrain.set_cells_terrain(terrainCells[tile], tile, Vector2i(WORLD_SIZE, WORLD_SIZE))
	
	for tile in floorCells:
		Tilemap.set_cells_autotile(floorCells[tile], tile, get_total_autotile_cells(floorCells))
	
	for tile in wallCells:
		Tilemap.set_cells_autotile(wallCells[tile], tile, get_total_autotile_cells(wallCells))
	
	for tile in objectCells:
		Tilemap.set_cells(objectCells[tile], tile)
	
	Tilemap.flush_batches()

func group_cells_by_tile() -> Dictionary:
	var grouped := {}
	for layer in CellDef.get_tile_layers():
		grouped[layer] = {}
	
	for cellPos in mapData:
		var cell :CellDef = mapData[cellPos]
		for layer in grouped:
			var tile :TileDef = cell.get(layer)
			
			if tile == TileManager.emptyTile:
				continue
			
			if not grouped[layer].has(tile):
				grouped[layer][tile] = []
			
			grouped[layer][tile].append(cellPos)
	
	return grouped

func get_total_autotile_cells(wallDb :Dictionary) -> Array:
	var total :Array = []
	for tile in wallDb: total.append_array(wallDb[tile])
	return total
