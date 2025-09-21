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
	#var timer1 = Time.get_ticks_msec()
	Regions.generate_regions(mapData)
	#var timer2 = Time.get_ticks_msec()
	#print("Msec: " + str(timer2-timer1))
	Pathfinding.update_pathfinding(mapData)
	
	Entities.summon_entity(Vector2i(126, 126))

func set_cell(cellPos :Vector2i, tileData :TileDef) -> void:
	var cellData :CellDef = mapData[cellPos]
	var layer :int = tileData.layer
	
	if cellData.tiles[layer] == tileData: return
	
	# Map data
	cellData.tiles[layer] = tileData
	
	# Autotile
	var is_autotile :bool = Tilemap.add_autotile_position(cellPos, tileData)
	if is_autotile:
		Tilemap.update_y_canvas_item(cellPos.y - 1, mapData)
		Tilemap.update_y_canvas_item(cellPos.y + 1, mapData)
	
	Tilemap.update_y_canvas_item(cellPos.y, mapData)
	
	# Region
	Regions.add_tile_index(Regions.get_tile_index(cellData.region, layer), tileData)
	
	# Pathfinding
	Pathfinding.update_tile_point(cellPos, mapData)

func clear_cell(cellPos :Vector2i, layer :int) -> void:
	var cellData :CellDef = mapData[cellPos]
	var tileData :TileDef = cellData.tiles[layer]
	
	if tileData == null: return
	
	# Map data
	mapData[cellPos].tiles[layer] = null
	
	# Autotile
	var was_autotile :bool = Tilemap.clear_autotile_position(cellPos, layer)
	if was_autotile:
		Tilemap.update_y_canvas_item(cellPos.y - 1, mapData)
		Tilemap.update_y_canvas_item(cellPos.y + 1, mapData)

	Tilemap.update_y_canvas_item(cellPos.y, mapData)
	
	# Region
	Regions.remove_tile_index(Regions.get_tile_index(cellData.region, layer), tileData)
	
	# Pathfinding
	Pathfinding.update_tile_point(cellPos, mapData)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		update_mouse_cell_pos()
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if Entities.selected:
				Entities.selected.move(mouseCellPos, true)
			clear_action()
		
		elif event.button_index == MOUSE_BUTTON_LEFT:
			process_action()
			Entities.update_selected(null)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		clear_action()
		Entities.update_selected(null)

func update_mouse_cell_pos() -> void:
	var globalPos :Vector2i = get_local_mouse_position()
	mouseCellPos = (globalPos / TILE_SIZE)
	var cellData :CellDef = mapData.get(mouseCellPos)
	
	WorldInfo.update_info(mouseCellPos, cellData)

func process_action() -> void:
	if !pendingAction: return
	get_viewport().set_input_as_handled()
	
	var action = pendingAction.action
	var args = []
		
	for arg in pendingAction.args:
		args.append(resolve_callables(arg))
		
	if action and action.is_valid():
		action.callv(args)

func resolve_callables(arg):
	if arg is Callable:
		if arg.get_argument_count() == 0:
			return arg.call()
		else:
			return arg
	elif arg is Array:
		var array: Array = []
		for element in arg:
			array.append(resolve_callables(element))
		return array
	return arg

func clear_action() -> void:
	pendingAction = null
	ActionHint.action_cleared()

func get_mouse_cell_pos() -> Vector2i:
	return mouseCellPos

func start_mining_job(cellPos :Vector2i) -> void:
	var wallData :TileDef = mapData[cellPos].tiles[2]
	if wallData == null: return
	
	var workAmount = wallData.work
	
	JobManager.add_job("mine", mouseCellPos, workAmount, Callable(self, "complete_mining_job"))

func complete_mining_job(cellPos :Vector2i) -> void:
	clear_cell(cellPos, 2)
