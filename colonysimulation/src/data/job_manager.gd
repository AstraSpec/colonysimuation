extends DbManager

signal try_request_job(job: JobDef)
signal job_assigned(entity: Node2D, job: JobDef)
signal job_cleared(job: JobDef)

var TILE_SIZE :int = Constants.get_tile_size()

var jobs :Array[JobDef]
var progressBars :Dictionary = {}

func _init() -> void:
	load_db("res://data/jobs/")

func add_job(id :String, targetCell :Vector2i, workAmount :float, completeAction :Callable) -> void:
	for job :JobDef in jobs:
		if job.targetCell == targetCell and job.id == id:
			return
	
	var Job :JobDef = JobDef.new(id, targetCell, workAmount, completeAction)
	jobs.append(Job)
	
	emit_signal("try_request_job")

func request_job(Entity :Node2D) -> JobDef:
	var potentialJobs :Array[JobDef] = []
	
	for job :JobDef in jobs:
		if not job.reserved:
			potentialJobs.append(job)
	
	if potentialJobs.is_empty():
		return null
	
	potentialJobs.sort_custom(func(a, b):
		return Entity.cellPos.distance_squared_to(a.targetCell) < Entity.cellPos.distance_squared_to(b.targetCell)
	)
	
	for job :JobDef in potentialJobs:
		if Entity.try_move(job.targetCell, false):
			job.reserved = true
			emit_signal("job_assigned", Entity, job)
			
			return job
	
	return null

func track_job(job :JobDef) -> void:
	if progressBars.has(job): return
	
	var Bar = preload("res://src/ui/work_progress_bar.tscn").instantiate()
	get_node("/root/Main/World").add_child(Bar)
	Bar.position = job.targetCell * TILE_SIZE
	Bar.position.y += TILE_SIZE / 3
	Bar.size = Vector2(16, 4)
	progressBars[job] = Bar

func update_job_progress(job: JobDef) -> void:
	if !progressBars.has(job): return
	
	var Bar = progressBars[job]
	Bar.value = clamp(job.workProgress / job.workAmount * 100, 0, 100)

func clear_job(job :JobDef) -> void:
	if !progressBars.has(job): return
	
	progressBars[job].queue_free()
	progressBars.erase(job)
	emit_signal("job_cleared", job)
