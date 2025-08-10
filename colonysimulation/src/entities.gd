extends Node2D

@onready var Entity :PackedScene = preload("res://src/entity/entity.tscn")

var selected :Node2D

func summon_entity(cellPos :Vector2i) -> void:
	var Colonist :Node2D = Entity.instantiate()
	Colonist.cellPos = cellPos
	add_child(Colonist)

func update_selected(entity :Node2D) -> void:
	if selected: selected.unselect()
	if entity: entity.select()
	
	selected = entity
