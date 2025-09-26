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

var dragCellOrigin :Vector2i
var isDragging :bool = false
var dragAppliedCells :Dictionary = {}
var dragSelection :RectangleShape2D = RectangleShape2D.new()

var pendingAction :ActionDef

func start() -> void:
	mapData = WorldGeneration.generate_world()
	Regions.generate_regions(mapData)
	Pathfinding.update_pathfinding(mapData)
	
	z_index = Constants.get_world_size()
	
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
	queue_redraw()
	
	if event is InputEventMouseMotion:
		update_mouse_cell_pos()
	
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if Entities.selected:
					Entities.selected.move(mouseCellPos, true)
				if isDragging:
					_end_drag()
					clear_action()
				else:
					clear_action()
			
			elif event.button_index == MOUSE_BUTTON_LEFT:
				process_action()
				Entities.update_selected(null)
		else:
			if event.button_index == MOUSE_BUTTON_LEFT and isDragging:
				_apply_drag_rect(dragCellOrigin, mouseCellPos)
				_end_drag()

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

func drag_cell(_action: Callable, _args: Array) -> void:
	dragCellOrigin = mouseCellPos
	isDragging = true
	dragAppliedCells.clear()

func _apply_drag_rect(fromCell: Vector2i, toCell: Vector2i) -> void:
	var min_x: int = min(fromCell.x, toCell.x)
	var max_x: int = max(fromCell.x, toCell.x)
	var min_y: int = min(fromCell.y, toCell.y)
	var max_y: int = max(fromCell.y, toCell.y)
	
	if pendingAction and pendingAction.args.size() >= 2:
		var drag_callable :Callable = pendingAction.args[0]
		var drag_args_template :Array = pendingAction.args[1]
		
		if drag_callable.is_valid():
			for y in range(min_y, max_y + 1):
				for x in range(min_x, max_x + 1):
					var cellPos: Vector2i = Vector2i(x, y)
					
					if dragAppliedCells.has(cellPos):
						continue
					dragAppliedCells[cellPos] = true
					var resolved_args: Array = []
					
					for arg in drag_args_template:
						resolved_args.append(resolve_callables(arg))
					
					if resolved_args.size() > 0:
						resolved_args[0] = cellPos
					
					drag_callable.callv(resolved_args)

func _end_drag() -> void:
	isDragging = false
	dragAppliedCells.clear()

func _draw() -> void:
	if isDragging:
		var topLeft: Vector2i = Vector2i(min(dragCellOrigin.x, mouseCellPos.x), min(dragCellOrigin.y, mouseCellPos.y))
		var bottomRight: Vector2i = Vector2i(max(dragCellOrigin.x, mouseCellPos.x), max(dragCellOrigin.y, mouseCellPos.y)) + Vector2i(1, 1)
		var rect := Rect2(Vector2(topLeft * TILE_SIZE), Vector2((bottomRight - topLeft) * TILE_SIZE))
		draw_rect(rect, Color.WHITE, false, 2.0)
	elif pendingAction:
		var rect := Rect2(mouseCellPos * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))
		draw_rect(rect, Color.WHITE, false, 2.0)

func start_mining_job(cellPos :Vector2i) -> void:
	var wallData :TileDef = mapData[cellPos].tiles[2]
	if wallData == null: 
		return
	
	var workAmount = wallData.work
	
	JobManager.add_job("mine", cellPos, workAmount, Callable(self, "complete_mining_job"))

func complete_mining_job(cellPos :Vector2i) -> void:
	clear_cell(cellPos, 2)
