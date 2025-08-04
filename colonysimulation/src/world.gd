extends Node2D

@export var WorldGeneration :Node2D
@export var Regions :Node2D

var mapData : Dictionary

func start() -> void:
	mapData = WorldGeneration.generate_world()
	Regions.generate_regions(mapData)
