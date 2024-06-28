@tool
class_name WireframeCube
extends ImmediateMesh

@export var size := Vector3(1, 1, 1):
	set(value):
		size = value
		update()

func _init() -> void:
	update()

func update() -> void:
	clear_surfaces()
	surface_begin(Mesh.PRIMITIVE_LINES)
	surface_add_vertex(Vector3(0, 0, 0))
	surface_add_vertex(Vector3(size.x, 0, 0))
	surface_add_vertex(Vector3(0, 0, 0))
	surface_add_vertex(Vector3(0, size.y, 0))
	surface_add_vertex(Vector3(0, 0, 0))
	surface_add_vertex(Vector3(0, 0, size.z))
	surface_add_vertex(Vector3(size.x, 0, 0))
	surface_add_vertex(Vector3(size.x, size.y, 0))
	surface_add_vertex(Vector3(size.x, 0, 0))
	surface_add_vertex(Vector3(size.x, 0, size.z))
	surface_add_vertex(Vector3(0, size.y, 0))
	surface_add_vertex(Vector3(size.x, size.y, 0))
	surface_add_vertex(Vector3(0, size.y, 0))
	surface_add_vertex(Vector3(0, size.y, size.z))
	surface_add_vertex(Vector3(0, 0, size.z))
	surface_add_vertex(Vector3(size.x, 0, size.z))
	surface_add_vertex(Vector3(0, 0, size.z))
	surface_add_vertex(Vector3(0, size.y, size.z))
	surface_add_vertex(Vector3(size.x, size.y, 0))
	surface_add_vertex(Vector3(size.x, size.y, size.z))
	surface_add_vertex(Vector3(size.x, 0, size.z))
	surface_add_vertex(Vector3(size.x, size.y, size.z))
	surface_add_vertex(Vector3(0, size.y, size.z))
	surface_add_vertex(Vector3(size.x, size.y, size.z))
	surface_end()
	
