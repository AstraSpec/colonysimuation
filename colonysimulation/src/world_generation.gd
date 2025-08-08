extends Node2D

@onready var ElevationNoise :FastNoiseLite = preload("res://assets/noise/elevation.tres")
@onready var GeologyNoise :FastNoiseLite = preload("res://assets/noise/geology.tres")
@onready var TreeNoise :FastNoiseLite = preload("res://assets/noise/trees.tres")
@onready var GrassNoise :FastNoiseLite = preload("res://assets/noise/grass.tres")
@onready var TallGrassNoise :FastNoiseLite = preload("res://assets/noise/tall_grass.tres")

@export var Tilemap :FastTileMap
@export var Terrain :TextureRect

var WORLD_SIZE :int = Constants.get_world_size()
var TILE_SIZE :int = Constants.get_tile_size()
var CHUNK_SIZE :int = Constants.get_chunk_size()

const TERRAIN_THRESHOLD :float = 0.27
const CLIFF_THRESHOLD :float = 0.3
const GRASS_THRESHOLD :float = 0.4
const TREE_THRESHOLD :float = 0.25
const TALL_GRASS_HIGH_THRESHOLD :float = 0.555
const TALL_GRASS_LOW_THRESHOLD :float = 0.45
const FLOWER_THRESHOLD :float = 0.05

func generate_world() -> Dictionary:
	Tilemap.clear_all()
	
	var mapData :Dictionary = {}
	
	for i in WORLD_SIZE ** 2:
		var cellPos := Vector2i(i / WORLD_SIZE, i % WORLD_SIZE)
		mapData[cellPos] = process_tile(cellPos)
	
	render_map(mapData)
	
	return mapData

func process_tile(cellPos :Vector2i) -> CellDef:
	var Cell := CellDef.new()
	
	var noise :Dictionary = {
		"elevation": ElevationNoise.get_noise_2d(cellPos.x, cellPos.y),
		"geology": GeologyNoise.get_noise_2d(cellPos.x, cellPos.y),
		"grass": GrassNoise.get_noise_2d(cellPos.x, cellPos.y),
		"tallGrass": TallGrassNoise.get_noise_2d(cellPos.x, cellPos.y),
		"tree": TreeNoise.get_noise_2d(cellPos.x, cellPos.y),
	}
	
	Cell.tiles.terrain = process_terrain(noise)
	Cell.tiles.floor = process_floor(noise)
	Cell.tiles.wall = process_wall(noise)
	Cell.tiles.object = process_object(noise)
	
	Cell.chunk = Vector2i(cellPos.x / CHUNK_SIZE, cellPos.y / CHUNK_SIZE)
	
	return Cell

func process_terrain(noise :Dictionary) -> TileDef:
	var type :String = "dirt_terrain"
	if noise.elevation > TERRAIN_THRESHOLD:
		type = "stone_terrain" if noise.geology > 0.0 else "mud_terrain"
	
	return TileManager.tileDb[type]

func process_wall(noise :Dictionary) -> TileDef:
	if noise.elevation > CLIFF_THRESHOLD:
		var type :String = "stone_wall" if noise.geology > 0.0 else "mud_wall"
		return TileManager.tileDb[type]
	return null

func process_floor(noise :Dictionary) -> TileDef:
	if noise.elevation <= TERRAIN_THRESHOLD:
		if noise.grass > GRASS_THRESHOLD:
			return TileManager.tileDb["grass"]
	return null

func process_object(noise :Dictionary) -> TileDef:
	if noise.elevation <= TERRAIN_THRESHOLD:
		var vegetation :String = get_vegetation(noise)
		if vegetation != "":
			return TileManager.tileDb[vegetation]
	return null

func get_vegetation(noise :Dictionary) -> String:
	if noise.tree > TREE_THRESHOLD:
		return "tree"
	
	elif noise.tallGrass > TALL_GRASS_HIGH_THRESHOLD:
		if randf() > FLOWER_THRESHOLD:
			return "tall_grass2"
		else:
			return "flower"
	elif noise.tallGrass > TALL_GRASS_LOW_THRESHOLD:
		return "tall_grass1"
	
	return ""

func render_map(mapData :Dictionary) -> void:
	var cells :Dictionary = group_cells_by_tile(mapData)
	
	var terrainCells :Dictionary = cells["terrain"]
	var floorCells :Dictionary = cells["floor"]
	var wallCells :Dictionary = cells["wall"]
	var objectCells :Dictionary = cells["object"]
	
	for tile in terrainCells:
		Terrain.set_cells_terrain(terrainCells[tile], tile)
	
	for tile in floorCells:
		Tilemap.set_cells_autotile(floorCells[tile], tile, get_total_autotile_cells(floorCells), false)
	
	for tile in wallCells:
		Tilemap.set_cells_autotile(wallCells[tile], tile, get_total_autotile_cells(wallCells), false)
	
	for tile in objectCells:
		Tilemap.set_cells(objectCells[tile], tile, false)
	
	Tilemap.redraw_tiles()

func group_cells_by_tile(mapData :Dictionary) -> Dictionary:
	var grouped := {}
	for layer in CellDef.get_tile_layers():
		grouped[layer] = {}
	
	for cellPos in mapData:
		var cell :CellDef = mapData[cellPos]
		for layer in grouped:
			var tile :TileDef = cell.tiles[layer]
			
			if tile == null:
				continue
			
			if not grouped[layer].has(tile):
				grouped[layer][tile] = []
			
			grouped[layer][tile].append(cellPos)
	
	return grouped

func get_total_autotile_cells(wallDb :Dictionary) -> Array:
	var total :Array = []
	for tile in wallDb: total.append_array(wallDb[tile])
	return total
