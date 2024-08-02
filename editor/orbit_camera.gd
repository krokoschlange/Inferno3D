class_name OrbitCamera
extends Node3D

@export var zoom_limits := Vector2(0.1, 100)
@export var speed: float = 0.01
@export var zoom_speed: float = 1.1
@export var move_speed: float = 0.001

@export var zoom: float = 15.0:
	set(value):
		zoom = clampf(value, zoom_limits.x, zoom_limits.y)

var yaw: float = 0.0
var pitch: float = 0.0

@onready var camera: Camera3D = $Camera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	camera.position.z = zoom
	rotation.y = yaw
	rotation.x = pitch

func set_current() -> void:
	camera.current = true

func _input(event: InputEvent) -> void:
	if not camera.current:
		return
	if event is InputEventMouseMotion and Input.is_action_pressed("rotate_camera"):
		if not Input.is_action_pressed("move_camera"):
			yaw -= event.relative.x * speed
			pitch -= event.relative.y * speed
			pitch = clampf(pitch, -PI / 2, PI / 2)
		else:
			translate_object_local(Vector3(-event.relative.x, event.relative.y, 0) * move_speed * zoom)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom /= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom *= zoom_speed

func recenter(pos: Vector3) -> void:
	if camera.current:
		var tween: Tween = create_tween()
		tween.tween_property(self, "global_position", pos, 0.1)
