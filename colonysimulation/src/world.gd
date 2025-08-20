extends Node2D

@export var WorldGeneration :Node2D
@export var Regions :Node2D
@export var Entities :Node2D
@export var Tilemap :FastTileMap
@export var Pathfinding :FastPathfinding
@export var WorldInfo :Label
@export var ActionHint :Control

static var TILE_SIZE :int = Constants.get_tile_size()

var mapData :Dictionary
var mouseCellPos :Vector2i

var pendingAction :ActionDef

func start() -> void:
	mapData = WorldGeneration.generate_world()
	Regions.generate_regions(mapData)
	Pathfinding.update_pathfinding(mapData)
	
	#set_cell(Vector2i(30, 227), TileManager.tileDb["pointer"])
	#set_cell(Vector2i(126, 130), TileManager.tileDb["pointer"])
	Entities.summon_entity(Vector2i(126, 126))

func set_cell(cellPos :Vector2i, tileData :TileDef) -> void:
	mapData[cellPos].tiles[tileData.layer] = tileData
	
	var is_autotile :bool = Tilemap.add_autotile_position(cellPos, tileData)
	Tilemap.update_y_canvas_item(cellPos.y, mapData)
	
	# If this is an autotile, update neighboring y-levels that might be affected
	if is_autotile:
		Tilemap.update_y_canvas_item(cellPos.y - 1, mapData)
		Tilemap.update_y_canvas_item(cellPos.y + 1, mapData)

func clear_cell(cellPos, layer) -> void:
	mapData[cellPos].tiles[layer] = null
	
	var was_autotile :bool = Tilemap.clear_autotile_position(cellPos, layer)
	Tilemap.update_y_canvas_item(cellPos.y, mapData)
	
	# Clear the autotile position if it was one
	if was_autotile:
		Tilemap.update_y_canvas_item(cellPos.y - 1, mapData)
		Tilemap.update_y_canvas_item(cellPos.y + 1, mapData)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		update_mouse_cell_pos()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Entities.selected:
			Entities.selected.move(mouseCellPos, Pathfinding)
		else:
			process_action()
		
		get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE or \
			event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		pendingAction = null
		ActionHint.action_cleared()
		Entities.update_selected(null)

func update_mouse_cell_pos() -> void:
	var globalPos :Vector2i = get_local_mouse_position()
	mouseCellPos = (globalPos / TILE_SIZE)
	var cellData :CellDef = mapData.get(mouseCellPos)
	
	WorldInfo.update_info(mouseCellPos, cellData)

func process_action() -> void:
	if !pendingAction: return
	
	var action = pendingAction.action
	var args = []
		
	for arg in pendingAction.args:
		args.append(resolve_callables(arg))
		
	if action and action.is_valid():
		action.callv(args)

func resolve_callables(arg):
	if arg is Callable:
		return arg.call()
	elif arg is Array:
		var array: Array = []
		for element in arg:
			array.append(resolve_callables(element))
		return array
	return arg

func get_mouse_cell_pos() -> Vector2i:
	return mouseCellPos
