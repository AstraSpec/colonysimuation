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
	JobManager.try_assign_job.connect(_on_try_assign_job)
	request_job()

func _process(delta: float) -> void:
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
	if job and path.is_empty():
		execute_job(delta)

func move(targetPos :Vector2i, complete_path :bool = false) -> bool:
	if !Pathfinding.is_end_reachable(targetPos):
		return false
		
	path = Pathfinding.find_path(cellPos, targetPos)
	
	if !complete_path:
		path.resize(path.size()-1)
	
	if Pathfinding.path_goes_through_solid(path):
		path.clear()
		return false
	
	return true

func assign_job(Job :JobDef) -> void:
	if job: return
	job = JobManager.find_job(Job, self)

func request_job() -> void:
	job = JobManager.request_job(self)

func path_to_job(Job :JobDef) -> bool:
	return move(Job.targetCell, false)

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
	
	request_job()

func _on_try_assign_job(Job: JobDef) -> void:
	assign_job(Job)

func _on_entity_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Entities.update_selected(self)
		get_viewport().set_input_as_handled()

func select() -> void:
	modulate = Color(1.5, 1.5, 1.5, 1.0)

func unselect() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)
