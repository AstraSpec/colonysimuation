extends Camera2D

var drag_speed :float = 1.75

var zoom_increment :float = 0.25
var zoom_min :float = 0.5
var zoom_max :float = 5

const MOUSE_WHEEL_UP :int = 4
const MOUSE_WHEEL_DOWN :int = 5

const MOVE_SPEED :float = 1000.0
var dir :Vector2

func _unhandled_input(event :InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		position -= event.relative * drag_speed / zoom
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_WHEEL_UP:
			zoom += Vector2(zoom_increment, zoom_increment)
		elif event.button_index == MOUSE_WHEEL_DOWN:
			zoom -= Vector2(zoom_increment, zoom_increment)
	
		zoom = zoom.clamp(Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))

func _process(delta :float) -> void:
	dir.x = Input.get_axis("a", "d")
	dir.y = Input.get_axis("w", "s")
	
	position += dir * MOVE_SPEED * delta / (zoom * 1.2)
