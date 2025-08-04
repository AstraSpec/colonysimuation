extends Region

var WORLD_SIZE :int = Constants.get_world_size()
var CHUNK_SIZE :int = Constants.get_chunk_size()
const FLOOD_FILL_DIRS :Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]

var regionData :Dictionary
var totalRegions :int = 0

func generate_regions(mapData :Dictionary) -> void:
	var ChunkCount = WORLD_SIZE / CHUNK_SIZE
	
	for i in ChunkCount ** 2:
		var chunkPos := Vector2i(i / ChunkCount, i % ChunkCount)
		create_regions(chunkPos, mapData)
	
	#TODO: Get neighbouring regions

# Creates regions within a given chunk.
func create_regions(chunkPos :Vector2i, mapData :Dictionary) -> void:
	for i in CHUNK_SIZE ** 2:
		var cellPos := Vector2i(i / CHUNK_SIZE, i % CHUNK_SIZE) + chunkPos * CHUNK_SIZE
		
		if mapData[cellPos].region == -1:
			var region := RegionDef.new()
			region.id = totalRegions
			
			regionData[totalRegions] = region
			flood_fill_region(cellPos, Vector2i.ZERO, mapData)
			totalRegions += 1

# Recursive function to perform flood-fill and assign regions to connected cells.
func flood_fill_region(pos :Vector2i, dir :Vector2i, mapData :Dictionary) -> void:
	var floodPos :Vector2i = pos + dir
	
	if mapData.get(floodPos) \
	and mapData[pos].chunk == mapData[floodPos].chunk \
	and mapData[floodPos].region == -1:
		
		mapData[floodPos].region = totalRegions
		regionData[totalRegions].cells.append(floodPos)
		
		for floodDir in FLOOD_FILL_DIRS:
			flood_fill_region(floodPos, floodDir, mapData)
