extends Node2D

@onready var Entity :PackedScene = preload("res://src/entity/entity.tscn")

var selected :Node2D
var entity_path_lines :Dictionary = {}

var TILE_SIZE = Constants.get_tile_size()

func summon_entity(cellPos :Vector2i) -> void:
	var Colonist :Node2D = Entity.instantiate()
	Colonist.cellPos = cellPos
	add_child(Colonist)
	
	_create_path_line(Colonist)

func update_selected(entity :Node2D) -> void:
	if selected: selected.unselect()
	if entity: entity.select()
	
	selected = entity

func _create_path_line(entity: Node2D) -> void:
	var path_line = Line2D.new()
	path_line.width = 2.0
	path_line.default_color = Color(1, 1, 1, 0.35)
	path_line.z_index = -1
	add_child(path_line)
	entity_path_lines[entity] = path_line

func update_entity_path(entity: Node2D, path: PackedVector2Array) -> void:
	if not entity_path_lines.has(entity):
		return
	
	var path_line = entity_path_lines[entity]
	path_line.clear_points()
	
	if path.is_empty():
		return
	
	# Add current entity position as first point
	path_line.add_point(entity.position + Vector2(TILE_SIZE/2, TILE_SIZE/2))
	
	# Add remaining path points
	for cell_pos in path:
		path_line.add_point(Vector2(cell_pos * Constants.get_tile_size()) + Vector2(TILE_SIZE/2, TILE_SIZE/2))

func remove_entity_path(entity: Node2D) -> void:
	if entity_path_lines.has(entity):
		entity_path_lines[entity].queue_free()
		entity_path_lines.erase(entity)
