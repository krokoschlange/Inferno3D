@tool
class_name WireframeArrow
extends ImmediateMesh

@export var length: float = 1.0:
	set(value):
		length = value
		update()
@export var radius: float = 0.1:
	set(value):
		radius = value
		update()
@export var tip_length: float = 0.33:
	set(value):
		tip_length = value
		update()
@export var tip_radius: float = 0.25:
	set(value):
		tip_radius = value
		update()

func _init() -> void:
	update()

func update() -> void:
	clear_surfaces()
	surface_begin(Mesh.PRIMITIVE_LINES)
	add_line(-radius, 0, 0, radius, 0, 0)
	add_line(0, -radius, 0, 0, radius, 0)
	
	add_line(-radius, 0, 0, -radius, 0, length - tip_length)
	add_line(radius, 0, 0, radius, 0, length - tip_length)
	add_line(0, -radius, 0, 0, -radius, length - tip_length)
	add_line(0, radius, 0, 0, radius, length - tip_length)
	
	add_line(-tip_radius, 0, length - tip_length, tip_radius, 0, length - tip_length)
	add_line(0, -tip_radius, length - tip_length, 0, tip_radius, length - tip_length)
	
	add_line(-tip_radius, 0, length - tip_length, 0, 0, length)
	add_line(tip_radius, 0, length - tip_length, 0, 0, length)
	add_line(0, -tip_radius, length - tip_length, 0, 0, length)
	add_line(0, tip_radius, length - tip_length, 0, 0, length)
	
	surface_end()

func add_line(x1: float, y1: float, z1: float, x2: float, y2: float, z2: float) -> void:
	surface_add_vertex(Vector3(x1, y1, z1))
	surface_add_vertex(Vector3(x2, y2, z2))
	
