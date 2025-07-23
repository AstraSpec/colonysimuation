extends Node2D

@export var WorldGeneration :Node2D

func _ready() -> void:
	WorldGeneration.generate_world()
