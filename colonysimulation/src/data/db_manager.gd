extends Node
class_name DbManager

var data :Array = []

func load_db(directory :String) -> void:
	var dir := DirAccess.open(directory)
	if not dir:
		push_error("Cannot access directory: " + directory)
		return
	
	var files :PackedStringArray = dir.get_files()
	var subdirs :PackedStringArray = dir.get_directories()
	
	for file :String in files:
		if file.ends_with(".json"):
			load_json_file(directory.path_join(file))
	
	for subdir :String in subdirs:
		load_db(directory.path_join(subdir))

func load_json_file(path :String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cannot access file: " + path)
		return
	
	var contents :String = file.get_as_text()
	var parse :Array = JSON.parse_string(contents)
	
	data.append_array(parse)

func get_data(id :String) -> Dictionary:
	for element :Dictionary in data:
		if element["id"] == id:
			return element
	
	push_error("No element found with the id ", id)
	return {}
