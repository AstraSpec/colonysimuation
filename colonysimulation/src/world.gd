extends Node2D

@export var WorldGeneration :Node2D
@export var Regions :Node2D
@export var Entities :Node2D
@export var WorldInfo :Label
@export var ActionHint :Control

var TILE_SIZE :int = Constants.get_tile_size()

var mapData :Dictionary
var mouseCellPos :Vector2i

var pendingAction :ActionDef

func start() -> void:
	var timer1 = Time.get_ticks_msec()
	mapData = WorldGeneration.generate_world()
	var timer2 = Time.get_ticks_msec()
	print(str(timer2-timer1))
	Regions.generate_regions(mapData)
	Entities.summon_entity(Vector2i(126, 126))
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		update_mouse_cell_pos()
	
	if Input.is_action_just_pressed("left_click"):
		process_action()

	if Input.is_action_just_pressed("esc") or Input.is_action_just_pressed("right_click"):
		pendingAction = null
		ActionHint.action_cleared()

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
