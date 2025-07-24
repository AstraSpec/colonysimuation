extends Node2D

@export var WorldGeneration :Node2D

func _ready() -> void:
	WorldGeneration.generate_world()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("z"):
		WorldGeneration.generate_world()
