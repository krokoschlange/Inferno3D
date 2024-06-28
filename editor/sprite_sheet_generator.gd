class_name SpriteSheetGenerator
extends TextureRect


var smoke_sim: SmokeSim
var viewport: RenderSceneVP
var progress: RenderProgressPopup

var skip_frames: int = 0
var grid: Vector2i
var resolution: Vector2i

var image: Image
var image_texture := ImageTexture.new()

var processing: bool
var skip_frame: int
var grid_pos: Vector2i

@onready var grid_editor: Vector2iEditor = $"../Container/MarginContainer/VBoxContainer/GridEditor"
@onready var skip_editor: IntEditor = $"../Container/MarginContainer/VBoxContainer/GridContainer/SkipEditor"

func _ready() -> void:
	grid_editor.value_changed.connect(func (new_value: Vector2i) -> void: grid = new_value)
	grid_editor.x_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		var old_vec2: Vector2i = grid
		old_vec2.x = old_value
		var new_vec2: Vector2i = grid
		new_vec2.x = new_value
		EditHistory.submit_object_actions([self], "grid", [old_vec2], [new_vec2], update_ui))
	grid_editor.y_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		var old_vec2: Vector2i = grid
		old_vec2.y = old_value
		var new_vec2: Vector2i = grid
		new_vec2.y = new_value
		EditHistory.submit_object_actions([self], "grid", [old_vec2], [new_vec2], update_ui))
	
	skip_editor.value_changed.connect(func (new_value: int) -> void: skip_frames = new_value)
	skip_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		EditHistory.submit_object_actions([self], "skip_frames", [old_value], [new_value], update_ui))

func _process(delta: float) -> void:
	if processing:
		if skip_frame == 0:
			copy_image()
		skip_frame += 1
		if skip_frame > skip_frames:
			skip_frame = 0

func generate() -> void:
	viewport.set_preview(true)
	viewport.set_pause(false)
	resolution = viewport.render_resolution
	skip_frames = skip_editor.value
	grid = grid_editor.value
	var total_res: Vector2i = resolution * grid
	image = Image.create(total_res.x, total_res.y, false, Image.FORMAT_RGBA8)
	image_texture.set_image(image)
	texture = image_texture
	skip_frame = 0
	grid_pos = Vector2i(0, 0)
	processing = true
	smoke_sim.clear_simulation()
	smoke_sim.run()
	progress.start(grid.x * grid.y)

func copy_image() -> void:
	viewport.sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var img: Image = viewport.sub_viewport.get_texture().get_image()
	var offset: Vector2i = grid_pos * resolution
	for x in img.get_width():
		for y in img.get_height():
			var col: Color = img.get_pixel(x, y)
			image.set_pixel(offset.x + x, offset.y + y, col)
	image_texture.set_image(image)
	progress.frame()
	grid_pos.x += 1
	if grid_pos.x >= grid.x:
		grid_pos.x = 0
		grid_pos.y += 1
	if grid_pos.y >= grid.y:
		processing = false
		progress.end()


func update_ui() -> void:
	grid_editor.set_value_no_signal(grid)
	skip_editor.set_value_no_signal(skip_frames)
