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
	
	#var foundTile = find_tile(119, TileManager.tileDb["pointer"], mapData)
	#print("LOOT GET at cell ", foundTile)

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
		
		# Only process cells that haven't been assigned to a region yet and are not solid
		if mapData[cellPos].region == -1 and !is_cell_solid(cellPos, mapData):
			var region := RegionDef.new()
			region.id = totalRegions
			
			for layer in TILE_LAYERS:
				region.tileIndex.append({})
			
			regionDb[totalRegions] = region
			# Start flood-fill from this cell in all directions
			flood_fill_region(cellPos, Vector2i.ZERO, mapData)
			totalRegions += 1

# Recursive function to perform flood-fill and assign regions to connected cells.
func flood_fill_region(pos :Vector2i, dir :Vector2i, mapData :Dictionary) -> void:
	var floodPos :Vector2i = pos + dir
	
	if mapData.get(floodPos) \
	and mapData[floodPos].region == -1 \
	and mapData[pos].chunk == mapData[floodPos].chunk \
	and !is_cell_solid(floodPos, mapData):
		
		mapData[floodPos].region = totalRegions
		regionDb[totalRegions].cells.append(floodPos)
		
		# Check all 4 directions to ensure complete flood-fill
		for floodDir in DIRS:
			flood_fill_region(floodPos, floodDir, mapData)

# Check if a cell is solid
func is_cell_solid(cellPos :Vector2i, mapData :Dictionary) -> bool:
	var cellData = mapData.get(cellPos)
	if !cellData:
		return false
	
	var tiles = cellData.tiles
	for tileData in tiles:
		if tileData != null and Constants.has_flag(tileData.flags, "SOLID"):
			return true
	
	return false

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
		
		for layer in cellData.tiles.size() -1:
			add_tile_index(regionData.tileIndex[layer+1], cellData.tiles[layer+1])

func add_tile_index(tileIndexes :Dictionary, tileData :TileDef):
	if tileData == null: return
	
	if tileIndexes.has(tileData):
		tileIndexes[tileData] += 1
	else:
		tileIndexes[tileData] = 1

func remove_tile_index(tileIndexes :Dictionary, tileData :TileDef):
	if tileData == null: return
	
	if tileIndexes.has(tileData):
		tileIndexes[tileData] -= 1
		
		if tileIndexes[tileData] == 0:
			tileIndexes.erase(tileData)

func get_tile_index(regionID :int, layer :int) -> Dictionary:
	return regionDb[regionID].tileIndex[layer]

func print_tile_indexes(regionID :int):
	var tileIndex :Array = regionDb[regionID].tileIndex
	
	for layer in tileIndex:
		for tile :TileDef in layer:
			prints(tile.id, layer[tile])

# Hierarchical pathfinding methods
func are_regions_connected(regionA :int, regionB :int) -> bool:
	if !regionDb.has(regionA) or !regionDb.has(regionB):
		return false
	
	if regionA == regionB:
		return true
	
	# Use BFS to check if there's any path between regions
	var visited :Array = []
	var queue :Array = [regionA]
	
	while queue.size() > 0:
		var currentRegion = queue.pop_front()
		
		if visited.has(currentRegion):
			continue
		
		visited.append(currentRegion)
		
		if currentRegion == regionB:
			return true
		
		# Add all connected regions to queue
		if regionDb.has(currentRegion):
			for neighbour_id in regionDb[currentRegion].neighbours.keys():
				if !visited.has(neighbour_id):
					queue.append(neighbour_id)
	
	return false

func assign_region_to_cell(cellPos :Vector2i, mapData :Dictionary) -> void:
	# Only assign regions within the same chunk
	var cellChunk = mapData[cellPos].chunk
	var surroundingRegions :Array = []
	
	# Check surrounding cells to find an existing region to join (only within same chunk)
	for dir in [Vector2i(-1,0), Vector2i(0,-1), Vector2i(0,1), Vector2i(1,0)]:
		var neighbourPos = cellPos + dir
		if mapData.has(neighbourPos):
			var neighbourData = mapData[neighbourPos]
			# Only consider neighbours within the same chunk
			if neighbourData.chunk == cellChunk:
				var neighbourRegion = neighbourData.region
				if neighbourRegion != -1 and !surroundingRegions.has(neighbourRegion):
					surroundingRegions.append(neighbourRegion)
	
	if surroundingRegions.size() > 0:
		# Join the first available region
		var targetRegion = surroundingRegions[0]
		mapData[cellPos].region = targetRegion
		regionDb[targetRegion].cells.append(cellPos)
	else:
		# Create a new region
		var newRegion = RegionDef.new()
		newRegion.id = totalRegions
		
		for layer in TILE_LAYERS:
			newRegion.tileIndex.append({})
		
		regionDb[totalRegions] = newRegion
		mapData[cellPos].region = totalRegions
		newRegion.cells.append(cellPos)
		totalRegions += 1
