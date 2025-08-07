extends Control

@export var ButtonContainer :VBoxContainer
@export var World :Node2D
@export var Entities :Node2D

@onready var DebugButton :PackedScene = preload("res://src/ui/debug/debug_button.tscn")

func init_debug() -> void:
	init_button("Summon entity", Callable(Entities, "summon_entity"), [Callable(World, "get_mouse_cell_pos")])

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
	hide()
