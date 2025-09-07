extends DbManager

var jobs :Array[JobDef]

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
