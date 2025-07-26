extends Label

@export var Camera :Camera2D

func _process(_delta: float) -> void:
	text = str(
		Engine.get_frames_per_second(), "\n",
		Camera.ZOOM_LEVELS[Camera.zoomLevel]
		)
	
	if Input.is_action_just_pressed("f3"):
		visible = !visible
