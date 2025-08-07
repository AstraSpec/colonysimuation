extends Node2D

@export var World :Node2D
@export var Camera :Camera2D

func _ready() -> void:
	World.start()
	Camera.start()

#TODO: 
# debug menu

# - entities
# pathfinding
# path searching

# - jobs
