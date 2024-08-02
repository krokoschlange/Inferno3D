class_name RenderSceneVP
extends SubViewportContainer

@onready var render_scene: RenderScene = $SubViewport/RenderScene
@onready var sub_viewport: SubViewport = $SubViewport
@onready var viewport_options: ViewportOptions = $"../MarginContainer2/ViewportOptions"

var render_resolution := Vector2i(128, 128):
	set(value):
		render_resolution = value
		render_scene.camera_3d.aspect_ratio = float(render_resolution.x) / render_resolution.y
		if not stretch:
			stretch = true
			stretch = false
			sub_viewport.size = render_resolution
		render_scene.albedo_vp.size = render_resolution
		render_scene.emission_vp.size = render_resolution
		render_scene.normal_vp.size = render_resolution
		render_scene.velocity_vp.size = render_resolution
var render_offset: Vector2:
	set(value):
		render_scene.camera_3d.offset = value
	get():
		return render_scene.camera_3d.offset
var render_scale: float:
	set(value):
		render_scene.camera_3d.size_factor = value
	get():
		return render_scene.camera_3d.size_factor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#set_preview(false)
	#pause_check_box.toggled.connect(render_scene.pause_simulation)
	viewport_options.preview_toggled.connect(set_preview)
	viewport_options.pause_toggled.connect(set_pause)
	viewport_options.render_mode_changed.connect(set_render_mode)
	render_resolution = Vector2i(128, 128)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var scale_factor: float = get_parent().size.y / sub_viewport.size.y
	scale = Vector2(scale_factor, scale_factor)
	
	if not stretch:
		var offset: float = (get_parent().size.x - sub_viewport.size.x * scale_factor) / 2
		global_position.x = get_parent().global_position.x + offset
	else:
		position.x = 0
		size = get_parent().size
	position.y = 0


func set_preview(on: bool) -> void:
	render_scene.set_preview(on)
	if on:
		stretch = false
		sub_viewport.size = render_resolution
	else:
		stretch = true
	#preview_check_box.set_pressed_no_signal(on)
	viewport_options.set_preview(on)

func set_pause(on: bool) -> void:
	render_scene.pause_simulation(on)
	viewport_options.set_pause(on)

func set_render_mode(mode: int) -> void:
	var base_mask: int = 1 & sub_viewport.get_camera_3d().cull_mask
	var mask: int = base_mask | (1 << mode + 1)
	sub_viewport.get_camera_3d().cull_mask = mask
	viewport_options.set_render_mode(mode)
