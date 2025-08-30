extends DbManager

var jobs :Array[JobDef]

func _init() -> void:
	load_db("res://data/jobs/")

func add_job(id :String, targetCell :Vector2i, node) -> void:
	var jobData :Dictionary = get_data(id)
	var Job :JobDef = JobDef.new(id, targetCell, Callable(node, id))
	jobs.append(Job)
	
	prints("Job with id:", id, "added at cell:", targetCell)

func find_job() -> JobDef:
	if jobs.is_empty(): 
		return null
	return jobs.pop_front()
