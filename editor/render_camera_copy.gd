@tool
extends Camera3D

@export var render_cam: RenderCamera


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if render_cam:
		size = render_cam.size
		global_position = render_cam.global_position
		near = render_cam.near
		far = render_cam.far
