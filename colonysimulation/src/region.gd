extends Region

const DIRS :Array[Vector2i] = [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]
const FLOOD_DIRS :Array[Vector2i] = [Vector2i.DOWN, Vector2i.RIGHT]
static var WORLD_SIZE :int = Constants.get_world_size()
static var CHUNK_SIZE :int = Constants.get_chunk_size()
static var TILE_LAYERS :Array = CellDef.get_tile_layers()

var regionDb :Dictionary
var totalRegions :int = 0

func generate_regions(mapData :Dictionary) -> void:
	var ChunkCount = WORLD_SIZE / CHUNK_SIZE
	
	for i in ChunkCount ** 2:
		var chunkPos := Vector2i(i / ChunkCount, i % ChunkCount)
		create_regions(chunkPos, mapData)
	
	for regionData :RegionDef in regionDb.values():
		get_neighbours(regionData, mapData)
		get_tile_indexes(regionData, mapData)
	
	var foundTile = find_tile(119, TileManager.tileDb["pointer"], mapData)
	print("LOOT GET at cell ", foundTile)
	
	print_tile_indexes(16)

# startID should be region or ID? neighbours RegionDefs or ids?
func find_tile(startID :int, tileData :TileDef, mapData :Dictionary) -> Vector2i:
	var visitedRegions: Array = []
	var queue: Array = [startID]

	while queue.size() > 0:
		var id = queue.pop_front()
		if visitedRegions.has(id):
			continue
		
		visitedRegions.append(id)
		
		var region: RegionDef = regionDb[id]
		var layer: int = tileData.layer
		
		# Found region
		if region.tileIndex[layer].has(tileData):
			return flood_fill_get_tile(region, tileData, mapData)
			
		# Add neighbors to queue
		for neighbour_id in region.neighbours.keys():
			if !visitedRegions.has(neighbour_id):
				queue.append(neighbour_id)
	
	return Vector2i(-1, -1)

func flood_fill_get_tile(region :RegionDef, tileData :TileDef, mapData :Dictionary) -> Vector2i:
	var layer: int = tileData.layer
	
	for cell :Vector2i in region.cells:
		if mapData[cell].tiles[layer] == tileData:
			return cell
	
	return Vector2i(-1, -1)

# Creates regions within a given chunk.
func create_regions(chunkPos :Vector2i, mapData :Dictionary) -> void:
	for i in CHUNK_SIZE ** 2:
		var cellPos := Vector2i(i / CHUNK_SIZE, i % CHUNK_SIZE) + chunkPos * CHUNK_SIZE
		
		if mapData[cellPos].region == -1:
			var region := RegionDef.new()
			region.id = totalRegions
			
			for layer in TILE_LAYERS:
				region.tileIndex.append({})
			
			regionDb[totalRegions] = region
			flood_fill_region(cellPos, Vector2i.ZERO, mapData)
			totalRegions += 1

# Recursive function to perform flood-fill and assign regions to connected cells.
func flood_fill_region(pos :Vector2i, dir :Vector2i, mapData :Dictionary) -> void:
	var floodPos :Vector2i = pos + dir
	
	if mapData.get(floodPos) \
	and mapData[floodPos].region == -1 \
	and mapData[pos].chunk == mapData[floodPos].chunk:
		
		mapData[floodPos].region = totalRegions
		regionDb[totalRegions].cells.append(floodPos)
		
		for floodDir in FLOOD_DIRS:
			flood_fill_region(floodPos, floodDir, mapData)

func get_neighbours(regionData :RegionDef, mapData :Dictionary) -> void:
	for cell in regionData.cells:
		if not is_chunk_edge(cell, mapData[cell].chunk):
			continue
		
		for dir in DIRS:
			var neighbourCell = mapData.get(cell + dir)
			if neighbourCell and neighbourCell.region != regionData.id:
				regionData.neighbours[neighbourCell.region] = true

func is_chunk_edge(cellPos :Vector2i, chunkPos :Vector2i) -> bool:
	var localPos :Vector2i = cellPos - chunkPos * CHUNK_SIZE
	return (localPos.x == 0 or localPos.x == CHUNK_SIZE - 1 or 
			localPos.y == 0 or localPos.y == CHUNK_SIZE - 1)

func get_tile_indexes(regionData :RegionDef, mapData :Dictionary) -> void:
	for cell in regionData.cells:
		var cellData :CellDef = mapData[cell]
		
		for layer in cellData.tiles.size():
			var tileData :TileDef = cellData.tiles[layer]
			
			if tileData == null: continue
			
			if regionData.tileIndex[layer].has(tileData):
				regionData.tileIndex[layer][tileData] += 1
			else:
				regionData.tileIndex[layer][tileData] = 1

func print_tile_indexes(regionID :int):
	var tileIndex :Array = regionDb[regionID].tileIndex
	
	for layer in tileIndex:
		for tile :TileDef in layer:
			prints(tile.id, layer[tile])
