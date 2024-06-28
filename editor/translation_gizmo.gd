class_name TranslationGizmo
extends Node3D

signal position_edited()
signal drag_started()

var selection: Array[SmokeSource] = []

var drag_start_coords: Array[Vector3]
var drag: bool
var drag_world_start: Vector3
var drag_world_dir: Vector3
var drag_screen_start: Vector2
var drag_screen_pos: Vector2
var drag_screen_dir: Vector2

@onready var mouse_collider_x: Area3D = $MouseColliderX
@onready var mouse_collider_y: Area3D = $MouseColliderY
@onready var mouse_collider_z: Area3D = $MouseColliderZ
@onready var arrow_x: MeshInstance3D = $MouseColliderX/ArrowX
@onready var arrow_y: MeshInstance3D = $MouseColliderY/ArrowY
@onready var arrow_z: MeshInstance3D = $MouseColliderZ/ArrowZ

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_hover_signals(mouse_collider_x, arrow_x, Color(0.867, 0.114, 0.141), Color(0.87, 0.496, 0.508))
	init_hover_signals(mouse_collider_y, arrow_y, Color(0.282, 0.694, 0), Color(0.63482791185379, 0.8359375, 0.50156253576279))
	init_hover_signals(mouse_collider_z, arrow_z, Color(0.173, 0.464, 0.695), Color(0.58757817745209, 0.7323437333107, 0.8515625))
	
	init_drag_signals(mouse_collider_x, Vector3.RIGHT)
	init_drag_signals(mouse_collider_y, Vector3.UP)
	init_drag_signals(mouse_collider_z, Vector3.BACK)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	var dist: float = (cam.global_position - global_position).length()
	scale = Vector3.ONE * dist * 0.1
	if selection.is_empty():
		hide()
		mouse_collider_x.process_mode = Node.PROCESS_MODE_DISABLED
		mouse_collider_y.process_mode = Node.PROCESS_MODE_DISABLED
		mouse_collider_z.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		show()
		mouse_collider_x.process_mode = Node.PROCESS_MODE_ALWAYS
		mouse_collider_y.process_mode = Node.PROCESS_MODE_ALWAYS
		mouse_collider_z.process_mode = Node.PROCESS_MODE_ALWAYS
		global_position = Vector3.ZERO
		for node in selection:
			global_position += node.global_position
		global_position /= selection.size()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and drag:
			var objs: Array[Object] = []
			var drag_end_coords: Array[Vector3] = []
			for src: SmokeSource in selection:
				objs.append(src)
				drag_end_coords.append(src.position)
			EditHistory.submit_object_actions(objs, "position", drag_start_coords, drag_end_coords, position_edited.emit)
			drag = false
	elif event is InputEventMouseMotion:
		if drag:
			drag_update(event.relative)

func init_hover_signals(collider: CollisionObject3D, mesh: MeshInstance3D, normal: Color, hover: Color) -> void:
	collider.mouse_entered.connect(func () -> void:
		var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
		mat.albedo_color = hover)
	collider.mouse_exited.connect(func () -> void:
		var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
		mat.albedo_color = normal)

func init_drag_signals(collider: CollisionObject3D, dir: Vector3) -> void:
	collider.input_event.connect(func (camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				drag_start(dir, event.position)
		)

func drag_start(dir: Vector3, pos: Vector2) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	var screen_pos: Vector2 = cam.unproject_position(global_position)
	var screen_dir: Vector2 = cam.unproject_position(global_position + dir)
	screen_dir -= screen_pos
	
	drag_start_coords = []
	for src: SmokeSource in selection:
		drag_start_coords.append(src.position)
	drag = true
	drag_world_start = global_position
	drag_world_dir = dir
	drag_screen_start = pos
	drag_screen_pos = pos
	drag_screen_dir = screen_dir
	drag_started.emit()

func drag_update(relative: Vector2) -> void:
	drag_screen_pos += relative
	var diff: Vector2 = drag_screen_pos - drag_screen_start
	var dist: float = diff.normalized().dot(drag_screen_dir.normalized())
	dist *= diff.length() / drag_screen_dir.length()
	var old_pos: Vector3 = global_position
	global_position = drag_world_start + dist * drag_world_dir
	var pos_diff: Vector3 = global_position - old_pos
	for node in selection:
		node.global_position += pos_diff
	position_edited.emit()
