extends Node2D

@export var WorldGeneration :Node2D
@export var Regions :Node2D

var mapData : Dictionary

func start() -> void:
	mapData = WorldGeneration.generate_world()
	
	#var timer1 = Time.get_ticks_msec()
	Regions.generate_regions(mapData)
	#var timer2 = Time.get_ticks_msec()
	
	#print(str(timer2-timer1))
