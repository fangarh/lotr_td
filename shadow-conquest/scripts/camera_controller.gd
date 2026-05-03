extends Camera3D

@export var target: Vector3 = Vector3(3.5, 0.0, 2.5)
@export var starting_position: Vector3 = Vector3(7.5, 8.0, 7.5)
@export var min_orthographic_size: float = 5.0
@export var max_orthographic_size: float = 16.0
@export var zoom_step: float = 0.9
@export var mouse_pan_speed: float = 0.018
@export var touch_pan_speed: float = 0.018
@export var drag_button: MouseButton = MOUSE_BUTTON_LEFT

var _is_dragging := false

func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = clampf(size, min_orthographic_size, max_orthographic_size)
	current = true
	global_position = starting_position
	look_at(target, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _is_dragging:
		var mouse_motion := event as InputEventMouseMotion
		_pan_by_screen_delta(mouse_motion.relative, mouse_pan_speed)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var screen_drag := event as InputEventScreenDrag
		_pan_by_screen_delta(screen_drag.relative, touch_pan_speed)
		get_viewport().set_input_as_handled()

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == drag_button:
		_is_dragging = event.pressed
		get_viewport().set_input_as_handled()
	elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_set_zoom(size * zoom_step)
		get_viewport().set_input_as_handled()
	elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_set_zoom(size / zoom_step)
		get_viewport().set_input_as_handled()

func _set_zoom(next_size: float) -> void:
	size = clampf(next_size, min_orthographic_size, max_orthographic_size)

func _pan_by_screen_delta(delta: Vector2, speed: float) -> void:
	var right := global_transform.basis.x
	var forward := global_transform.basis.z
	right.y = 0.0
	forward.y = 0.0
	right = right.normalized()
	forward = forward.normalized()

	var world_delta := ((-right * delta.x) + (-forward * delta.y)) * speed * size
	global_position += world_delta
	target += world_delta
