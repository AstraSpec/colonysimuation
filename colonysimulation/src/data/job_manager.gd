extends DbManager

var TILE_SIZE :int = Constants.get_tile_size()

var jobs :Array[JobDef]
var progressBars :Dictionary = {}

func _init() -> void:
	load_db("res://data/jobs/")

func add_job(id :String, targetCell :Vector2i, workAmount :float, completeAction :Callable) -> void:
	var Job :JobDef = JobDef.new(id, targetCell, workAmount, completeAction)
	jobs.append(Job)
	
	prints("Job with id:", id, "added at cell:", targetCell)

func find_job() -> JobDef:
	if jobs.is_empty(): 
		return null
	return jobs.pop_front()

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
