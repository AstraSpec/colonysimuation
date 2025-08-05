extends Label

@export var World :Node2D

var WORLD_SIZE :int = Constants.get_world_size()
var TILE_SIZE :int = Constants.get_tile_size()
var EMPTY_TILE :TileDef = TileManager.emptyTile

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var globalPos :Vector2i = World.get_local_mouse_position()
		var cellPos :Vector2i = (globalPos / TILE_SIZE)
		
		var cellData :CellDef = World.mapData.get(cellPos)
		if cellData:
			var info :Array = []
			for layer in CellDef.get_tile_layers():
				var tileData :TileDef = cellData.get(layer)
				if tileData != EMPTY_TILE:
					info.append(tileData.id)
			
			info.append(str("Region: ", cellData.region))
			
			info.append(str(cellData.chunk))
			info.append(str(cellPos))
			
			text = "\n".join(info)
