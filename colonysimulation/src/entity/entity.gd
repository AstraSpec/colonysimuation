extends Node2D

@onready var Entities :Node2D = get_parent()

static var TILE_SIZE :int = Constants.get_tile_size()

var cellPos :Vector2i = Vector2i.ZERO
var path :PackedVector2Array
var speed :float = 150.0

func _ready() -> void:
	position = cellPos * TILE_SIZE

func _process(delta: float) -> void:
	process_pathing(delta)

func process_pathing(delta :float) -> void:
	if path.size() > 0:
		var pathPos :Vector2 = path[0] * TILE_SIZE
		
		if position.distance_to(pathPos) < 1:
			cellPos = path[0]
			position = pathPos
			z_index = cellPos.y
			path.remove_at(0)
		else:
			position += (pathPos - position).normalized() * speed * delta

func _on_entity_area_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_action_just_pressed("left_click"):
		Entities.update_selected(self)

func move(mouseCellPos :Vector2i, Fastpathfinding) -> void:
	path = Fastpathfinding.find_path(cellPos, mouseCellPos)

func select() -> void:
	modulate = Color(1.5, 1.5, 1.5, 1.0)

func unselect() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)
