extends CanvasLayer

@export var DebugMenu :Control

func init_ui() -> void:
	DebugMenu.init_debug()

func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("f2"):
		DebugMenu.visible = !DebugMenu.visible
