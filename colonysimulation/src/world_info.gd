extends Label

var WORLD_SIZE :int = Constants.get_world_size()
var TILE_SIZE :int = Constants.get_tile_size()

func update_info(cellPos :Vector2i, cellData :CellDef) -> void:
	if !cellData:
		visible = false
		return
	visible = true
	
	var info :Array = []
	for tileData :TileDef in cellData.tiles.values():
		if tileData != null:
			info.append(tileData.id)
	
	info.append(str("Region: ", cellData.region))
	info.append(str(cellData.chunk))
	info.append(str(cellPos))
	
	text = "\n".join(info)
