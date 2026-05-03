# Simple free-fly observer camera for inspecting the simulation.
extends Camera3D

@export var move_speed: float = 8.0
@export var sprint_multiplier: float = 2.0
@export var look_sensitivity: float = 0.003
@export var capture_mouse_on_start: bool = true

var _yaw: float = 0.0
var _pitch: float = 0.0


func _ready() -> void:
	var euler = global_rotation
	_pitch = euler.x
	_yaw = euler.y
	if capture_mouse_on_start:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	# Mouse motion rotates camera while cursor is captured.
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * look_sensitivity
		_pitch -= event.relative.y * look_sensitivity
		_pitch = clamp(_pitch, -1.4, 1.4)
		rotation = Vector3(_pitch, _yaw, 0.0)

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event.keycode == KEY_TAB:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	# WASD + QE movement in local camera space.
	var dir = Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		dir += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		dir += transform.basis.x
	if Input.is_key_pressed(KEY_E):
		dir += transform.basis.y
	if Input.is_key_pressed(KEY_Q):
		dir -= transform.basis.y

	if dir != Vector3.ZERO:
		dir = dir.normalized()

	var speed = move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= sprint_multiplier

	global_position += dir * speed * delta
