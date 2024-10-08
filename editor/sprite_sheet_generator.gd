class_name SpriteSheetGenerator
extends TextureRect


var smoke_sim: SmokeSim
var viewport: RenderSceneVP
var progress: RenderProgressPopup

var skip_frames: int = 10
var grid := Vector2i(4, 4)
var resolution: Vector2i

var image: Image
var albedo: Image
var emission: Image
var normal: Image
var velocity: Image
var image_texture := ImageTexture.new()
var albedo_texture := ImageTexture.new()
var emission_texture := ImageTexture.new()
var normal_texture := ImageTexture.new()
var velocity_texture := ImageTexture.new()

var processing: bool
var skip_frame: int
var grid_pos: Vector2i
var crossfade_amount: int
var crossfade_frame: int

var was_preview: bool
var was_at_frame: int
var was_in_mode: int

@onready var grid_editor: Vector2iEditor = $"../../Container/MarginContainer/VBoxContainer/GridEditor"
@onready var skip_editor: IntEditor = $"../../Container/MarginContainer/VBoxContainer/GridContainer/SkipEditor"
@onready var texture_selector: OptionButton = $"../HBoxContainer/OptionButton"
@onready var loop_amount_editor: IntEditor = $"../../Container/MarginContainer/VBoxContainer/GridContainer/LoopAmountEditor"


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
	
	loop_amount_editor.value_changed.connect(func (new_value: int) -> void: crossfade_amount = new_value)
	loop_amount_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		EditHistory.submit_object_actions([self], "crossfade_amount", [old_value], [new_value], update_ui))
	
	texture = image_texture
	texture_selector.item_selected.connect(func (index: int) -> void:
		match index:
			0:
				texture = image_texture
			1:
				texture = albedo_texture
			2:
				texture = emission_texture
			3:
				texture = normal_texture
			4:
				texture = velocity_texture
		)

func _process(delta: float) -> void:
	if processing:
		if AnimationHandler.current_frame < 0:
			return
		if skip_frame == 0:
			copy_image()
		skip_frame += 1
		if skip_frame > skip_frames:
			skip_frame = 0

func generate() -> void:
	was_preview = viewport.preview
	was_at_frame = AnimationHandler.current_frame
	was_in_mode = viewport.render_mode
	viewport.set_preview(true)
	viewport.set_pause(false)
	viewport.set_render_mode(0)
	resolution = viewport.render_resolution
	skip_frames = skip_editor.value
	grid = grid_editor.value
	var total_res: Vector2i = resolution * grid
	image = Image.create(total_res.x, total_res.y, false, Image.FORMAT_RGBA8)
	albedo = Image.create(total_res.x, total_res.y, false, Image.FORMAT_RGBA8)
	emission = Image.create(total_res.x, total_res.y, false, Image.FORMAT_RGBA8)
	normal = Image.create(total_res.x, total_res.y, false, Image.FORMAT_RGBA8)
	velocity = Image.create(total_res.x, total_res.y, false, Image.FORMAT_RGBA8)
	image_texture.set_image(image)
	albedo_texture.set_image(albedo)
	emission_texture.set_image(emission)
	normal_texture.set_image(normal)
	velocity_texture.set_image(velocity)
	
	crossfade_amount = loop_amount_editor.value
	crossfade_frame = -1
	
	skip_frame = 0
	grid_pos = Vector2i(0, 0)
	AnimationHandler.playing = true
	AnimationHandler.current_frame = -AnimationHandler.warmup
	processing = true
	smoke_sim.clear_simulation()
	smoke_sim.run()
	progress.start(grid.x * grid.y)

func copy_image() -> void:
	viewport.sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.render_scene.albedo_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.render_scene.emission_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.render_scene.normal_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.render_scene.velocity_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	var offset: Vector2i = grid_pos * resolution
	
	if crossfade_frame < 0:
		var img: Image = viewport.sub_viewport.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		image.blit_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), offset)
		image_texture.set_image(image)
		
		img = viewport.render_scene.albedo_vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		albedo.blit_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), offset)
		albedo_texture.set_image(albedo)
		
		img = viewport.render_scene.emission_vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		emission.blit_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), offset)
		emission_texture.set_image(emission)
		
		img = viewport.render_scene.normal_vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		normal.blit_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), offset)
		normal_texture.set_image(normal)
		
		img = viewport.render_scene.velocity_vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		velocity.blit_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), offset)
		velocity_texture.set_image(velocity)
	else:
		offset = Vector2i(crossfade_frame % grid.x, crossfade_frame / grid.x) * resolution
		var alpha: float = 1 - float(crossfade_frame + 1) / (crossfade_amount + 1)
		
		var img: Image = viewport.sub_viewport.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		var data: PackedByteArray = img.get_data()
		for i: int in data.size() / 4:
			data[i * 4 + 3] = clampi(data[i * 4 + 3] * alpha, 0, 255)
		img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
		image.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), offset)
		image_texture.set_image(image)
		
		img = viewport.render_scene.albedo_vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		data = img.get_data()
		for i: int in data.size() / 4:
			data[i * 4 + 3] = clampi(data[i * 4 + 3] * alpha, 0, 255)
		img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
		albedo.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), offset)
		albedo_texture.set_image(albedo)
		
		img = viewport.render_scene.emission_vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		data = img.get_data()
		for i: int in data.size() / 4:
			data[i * 4 + 3] = clampi(data[i * 4 + 3] * alpha, 0, 255)
		img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
		emission.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), offset)
		emission_texture.set_image(emission)
		
		img = viewport.render_scene.normal_vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		data = img.get_data()
		for i: int in data.size() / 4:
			data[i * 4 + 3] = clampi(data[i * 4 + 3] * alpha, 0, 255)
		img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
		normal.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), offset)
		normal_texture.set_image(normal)
		
		img = viewport.render_scene.velocity_vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		data = img.get_data()
		for i: int in data.size() / 4:
			data[i * 4 + 3] = clampi(data[i * 4 + 3] * alpha, 0, 255)
		img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
		velocity.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), offset)
		velocity_texture.set_image(velocity)
	
	progress.frame()
	grid_pos.x += 1
	if grid_pos.x >= grid.x:
		grid_pos.x = 0
		grid_pos.y += 1
	if grid_pos.y >= grid.y and crossfade_frame < 0 and crossfade_amount > 0:
		crossfade_frame = 0
	elif crossfade_frame >= 0 and crossfade_frame < crossfade_amount - 1:
		crossfade_frame += 1
	elif grid_pos.y >= grid.y:
		processing = false
		AnimationHandler.playing = false
		AnimationHandler.current_frame = was_at_frame
		viewport.set_preview(was_preview)
		viewport.set_render_mode(was_in_mode)
		progress.end()


func update_ui() -> void:
	grid_editor.set_value_no_signal(grid)
	skip_editor.set_value_no_signal(skip_frames)
	loop_amount_editor.set_value_no_signal(crossfade_amount)


func open_export_window() -> void:
	var dialog := FileDialog.new()
	add_child(dialog)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.use_native_dialog = true
	dialog.show()
	
	dialog.file_selected.connect(export)

func export(path: String) -> void:
	if not image:
		return
	path = path.rsplit(".")[0]
	image.save_png(path + "_combined.png")
	albedo.save_png(path + "_albedo.png")
	emission.save_png(path + "_emission.png")
	normal.save_png(path + "_normal.png")
	velocity.save_png(path + "_velocity.png")
