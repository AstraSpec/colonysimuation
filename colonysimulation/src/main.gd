extends Node2D

@export var WorldGeneration :FastTileMap

func _ready() -> void:
	WorldGeneration.generate_world()
