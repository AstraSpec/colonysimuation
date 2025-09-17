class_name JobDef

var id :String
var targetCell :Vector2i
var completeAction :Callable

var workAmount :float = 1.0
var workProgress :float = 0.0

var reserved :bool = false

func _init(_id :String, _targetCell :Vector2i, _workAmount :float, _completeAction :Callable) -> void:
	id = _id
	targetCell = _targetCell
	workAmount = _workAmount
	completeAction = _completeAction
