extends Node2D

@export var World :Node2D
@export var Tilemap :FastTileMap

func spawn_item(cellPos: Vector2i, item :ItemDef, quantity: int) -> void:
	Tilemap.add_canvas_item(FastTileMap.CANVAS_ITEM_LAYER_ITEMS, cellPos, item.texture, item.atlas)
	World.mapData[cellPos].item = item
	World.mapData[cellPos].quantity = quantity

func clear_item(cellPos :Vector2i, quantity :int) -> void:
	Tilemap.remove_canvas_item(FastTileMap.CANVAS_ITEM_LAYER_ITEMS, cellPos)

#func get_items_at(cellPos: Vector2i) -> Array:
#	pass
