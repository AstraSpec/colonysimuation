class_name ActionDef
extends RefCounted

var name :String
var action :Callable
var args :Array
var validation :Callable

func _init(_name: String, _action: Callable, _args: Array, _validation :Callable):
	name = _name
	action = _action
	args = _args.duplicate()
	validation = _validation
