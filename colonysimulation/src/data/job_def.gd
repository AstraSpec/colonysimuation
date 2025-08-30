class_name JobDef

var id :String
var targetCell :Vector2i
var action :Callable

func _init(_id :String, _targetCell :Vector2i, _action :Callable) -> void:
	id = _id
	targetCell = _targetCell
	action = _action
	
