extends Control

@export var ActionLabel :Label

func _physics_process(_delta: float) -> void:
	position = get_global_mouse_position() + Vector2(8, 8)

func action_selected(text :String) -> void:
	ActionLabel.text = text
	show()

func action_cleared() -> void:
	ActionLabel.text = ""
	hide()
