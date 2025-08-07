extends Node2D

@export var World :Node2D
@export var Camera :Camera2D
@export var UI :CanvasLayer

func _ready() -> void:
	World.start()
	Camera.start()
	UI.init_ui()

#TODO: 
# debug menu

# - entities
# pathfinding
# path searching

# - jobs
