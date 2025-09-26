extends Control

@export var ButtonContainer :VBoxContainer
@export var World :Node2D
@export var Entities :Node2D
@export var FastTilemap :FastTileMap
@export var ActionHint :Control

@onready var DebugButton :PackedScene = preload("res://src/ui/debug/debug_button.tscn")

var mouse_cell_pos :Callable

func _ready() -> void:
	mouse_cell_pos = Callable(World, "get_mouse_cell_pos")

func init_debug() -> void:
	init_button("Summon entity", Callable(Entities, "summon_entity"), [mouse_cell_pos])
	init_button("Spawn tree", Callable(World, "set_cell"), [mouse_cell_pos, TileManager.tileDb["tree"]])
	init_button("Spawn wall", Callable(World, "drag_cell"), [Callable(World, "set_cell"), [mouse_cell_pos, TileManager.tileDb["stone_wall"]]])
	init_button("Clear wall", Callable(World, "drag_cell"), [Callable(World, "clear_cell"), [mouse_cell_pos, 2]])
	init_button("Add mining job", Callable(World, "drag_cell"), [Callable(World, "start_mining_job"), [mouse_cell_pos]])

func init_button(text :String, action :Callable, args = []) -> void:
	var instance = DebugButton.instantiate()
	ButtonContainer.add_child(instance)
	instance.text = text
	instance.action = action
	instance.args = args
	instance.pressed.connect(_on_debug_button_pressed.bind(instance))

func _on_debug_button_pressed(button: Button) -> void:
	var pendingAction = ActionDef.new(
	button.text,
	button.action,
	button.args)
	
	World.pendingAction = pendingAction
	ActionHint.action_selected(button.text)
	hide()
