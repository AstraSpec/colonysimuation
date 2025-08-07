class_name ActionDef
extends RefCounted

var name :String
var action :Callable
var args :Array

func _init(_name: String, _action: Callable, _args: Array):
	name = _name
	action = _action
	args = _args.duplicate()
