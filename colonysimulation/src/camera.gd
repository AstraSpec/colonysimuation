extends Camera2D

const DRAG_SPEED :float = 1.75
const MOVE_SPEED :float = 1000.0

const ZOOM_LEVELS :Array = [0.15, 0.25, 0.33, 0.5, 0.66, 1.0, 2.0]

var zoomLevel :int = 3
var scrolled :bool = false
var dir :Vector2

func start() -> void:
	var centre = Constants.get_tile_size() * Constants.get_world_size() / 2
	position = Vector2(centre, centre)

func _unhandled_input(event :InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		position -= event.relative * DRAG_SPEED / zoom
	
	elif scrolled:
		return
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_zoom(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_zoom(-1)

func change_zoom(amount :int) -> void:
	zoomLevel = clamp(zoomLevel + amount, 0, ZOOM_LEVELS.size() - 1)
	zoom = Vector2(ZOOM_LEVELS[zoomLevel], ZOOM_LEVELS[zoomLevel])
	
	scrolled = true

func _process(delta :float) -> void:
	scrolled = false
	
	dir.x = Input.get_axis("a", "d")
	dir.y = Input.get_axis("w", "s")
	
	position += dir * MOVE_SPEED * delta / (zoom * 1.2)
