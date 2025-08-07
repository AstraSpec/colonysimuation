extends Node2D

@onready var Entity :PackedScene = preload("res://src/entity/entity.tscn")

func summon_entity(cellPos :Vector2i) -> void:
	var Colonist :Node2D = Entity.instantiate()
	add_child(Colonist)
	
	Colonist.position = Constants.get_tile_size() * cellPos
