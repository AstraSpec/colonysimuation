extends Node2D

@onready var Pathfinding :FastPathfinding = get_node("/root/Main/World/FastPathfinding")
@onready var Entities :Node2D = get_parent()
@onready var Area :CollisionShape2D = $EntityArea/CollisionShape2D

static var TILE_SIZE :int = Constants.get_tile_size()

var cellPos :Vector2i = Vector2i.ZERO
var path :PackedVector2Array
var speed :float = 150.0

const TICK_RATE :float = 1.5
var tick :float = 0.0

var job :JobDef

func _ready() -> void:
	position = cellPos * TILE_SIZE

func _process(delta: float) -> void:
	tick += delta
	process_pathing(delta)
	process_job(delta)

func process_pathing(delta :float) -> void:
	if path.size() > 0:
		var pathPos :Vector2 = path[0] * TILE_SIZE
		
		if position.distance_to(pathPos) < 1:
			cellPos = path[0]
			position = pathPos
			z_index = cellPos.y
			path.remove_at(0)
			
			if path.size() == 0 and job != null:
				start_job()
		else:
			position += (pathPos - position).normalized() * speed * delta

func process_job(delta :float) -> void:
	if job == null:
		if tick > TICK_RATE:
			tick = 0
			find_job()
			print("PROCESS JOB")
	
	elif path.is_empty():
		execute_job(delta)

func move(targetPos :Vector2i, complete_path :bool = false) -> bool:
	path = Pathfinding.find_path(cellPos, targetPos)
	
	if !complete_path:
		path.resize(path.size()-1)
	
	if Pathfinding.path_goes_through_solid(path):
		path.clear()
		return false
	
	return true

func find_job() -> void:
	job = JobManager.find_job()
	if job and move(job.targetCell, false):
		JobManager.reserve_job(job)
	else:
		job = null

func start_job() -> void:
	JobManager.track_job(job)

func execute_job(delta :float) -> void:
	job.workProgress += delta
	JobManager.update_job_progress(job)
	
	if job.workProgress >= job.workAmount:
		complete_job()

func complete_job() -> void:
	job.completeAction.callv([job.targetCell])
	JobManager.clear_job(job)
	job = null

func _on_entity_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Entities.update_selected(self)
		get_viewport().set_input_as_handled()

func select() -> void:
	modulate = Color(1.5, 1.5, 1.5, 1.0)

func unselect() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)
