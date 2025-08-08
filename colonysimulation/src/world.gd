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
	mapData = WorldGeneration.generate_world()
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
	var args = pendingAction.args.duplicate()
		
	for i in args.size():
		if args[i] is Callable:
			args[i] = args[i].call()
		
	if action and action.is_valid():
		action.callv(args)

func get_mouse_cell_pos() -> Vector2i:
	return mouseCellPos
