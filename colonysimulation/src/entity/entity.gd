extends Node2D

@onready var Pathfinding :FastPathfinding = get_node("/root/Main/World/FastPathfinding")
@onready var Entities :Node2D = get_parent()
@onready var Area :CollisionShape2D = $EntityArea/CollisionShape2D

static var TILE_SIZE :int = Constants.get_tile_size()

var cellPos :Vector2i = Vector2i.ZERO
var path :PackedVector2Array
var speed :float = 150.0

var job :JobDef

func _ready() -> void:
	position = cellPos * TILE_SIZE

func _process(delta: float) -> void:
	process_pathing(delta)
	process_job()

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

func process_job() -> void:
	if job == null:
		job = JobManager.find_job()
		if job:
			move(job.targetCell)
	
	elif path.is_empty() and cellPos == job.targetCell:
		job.action.call()
		job = null

func _on_entity_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Entities.update_selected(self)

func move(targetPos :Vector2i) -> void:
	path = Pathfinding.find_path(cellPos, targetPos)

func select() -> void:
	modulate = Color(1.5, 1.5, 1.5, 1.0)

func unselect() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)
