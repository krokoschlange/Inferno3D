class_name SourceSelectionGizmo
extends Node3D

signal selected()

var source: SmokeSource:
	set(value):
		source = value
		update()

var is_selected: bool = false:
	set(value):
		is_selected = value
		mesh_node.get_surface_override_material(0).set_shader_parameter("selected", is_selected)

@onready var area_3d: Area3D = $Area3D
@onready var shape_node: CollisionShape3D = $Area3D/CollisionShape3D
@onready var shape := shape_node.shape as SphereShape3D
@onready var mesh_node: MeshInstance3D = $MeshInstance3D
@onready var mesh := mesh_node.mesh as QuadMesh


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_3d.input_event.connect(on_area_input_event)
	update()

func on_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selected.emit()

func update() -> void:
	if source and mesh and shape:
		mesh.size = Vector2.ONE * source.radius * 2
		shape.radius = source.radius
