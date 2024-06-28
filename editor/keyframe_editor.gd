@tool
class_name KeyframeEditor
extends Control

@export var kf_texture: Texture2D
@export var kf_texture_highlight: Texture2D

@onready var play_button: TextureButton = $"../../../../MarginContainer/HBoxContainer/PlayButton"
@onready var stop_button: TextureButton = $"../../../../MarginContainer/HBoxContainer/StopButton"
@onready var animation_selector: OptionButton = $"../../../../MarginContainer/HBoxContainer/AnimationSelector"
@onready var scroll_container: ScrollContainer = $"../../.."
@onready var warmup_editor: IntEditor = $"../../../../../../PanelContainer/MarginContainer/GridContainer/WarmupEditor"
@onready var length_editor: IntEditor = $"../../../../../../PanelContainer/MarginContainer/GridContainer/LengthEditor"


var animation: PropertyAnimation:
	set(value):
		animation = value
		queue_redraw()
var zoom: float = 7.0:
	set(value):
		zoom = value
		update_ui()

var current_frame: int:
	set(value):
		current_frame = value
		queue_redraw()

var dragging: bool = false

func _ready() -> void:
	play_button.toggled.connect(func (on: bool) -> void: AnimationHandler.playing = on)
	stop_button.pressed.connect(func () -> void:
		AnimationHandler.playing = false
		AnimationHandler.current_frame = -AnimationHandler.warmup
		play_button.set_pressed_no_signal(false))
	AnimationHandler.frame_changed.connect(func () -> void: current_frame = AnimationHandler.current_frame)
	AnimationHandler.animation_ended.connect(func () -> void: play_button.set_pressed_no_signal(false))
	AnimationHandler.animations_changed.connect(update_animation_list)
	AnimationHandler.animations_changed.connect(queue_redraw)
	animation_selector.item_selected.connect(func (id: int) -> void: animation = AnimationHandler.animations[id])
	
	warmup_editor.value_changed.connect(func (new_value: int) -> void:
		AnimationHandler.warmup = new_value
		update_ui())
	warmup_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		EditHistory.submit_object_actions([AnimationHandler], "warmup", [old_value], [new_value], update_ui))
	length_editor.value_changed.connect(func (new_value: int) -> void:
		AnimationHandler.end = new_value
		update_ui())
	length_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		EditHistory.submit_object_actions([AnimationHandler], "end", [old_value], [new_value], update_ui))
	update_ui()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var hscroll: float = float(event.position.x) / custom_minimum_size.x
			zoom /= 1.3
			scroll_container.get_h_scroll_bar().value = clampf(hscroll * (custom_minimum_size.x - scroll_container.size.x), 0, custom_minimum_size.x)
			queue_redraw()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var hscroll: float = float(event.position.x) / custom_minimum_size.x
			zoom *= 1.3
			scroll_container.get_h_scroll_bar().value = clampf(hscroll * (custom_minimum_size.x - scroll_container.size.x), 0, custom_minimum_size.x)
			queue_redraw()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var frame: int = roundi(event.position.x / zoom)
			frame -= AnimationHandler.warmup
			frame = clampi(frame, -AnimationHandler.warmup, AnimationHandler.end)
			AnimationHandler.current_frame = frame
			dragging = true
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
			var frame: int = roundi(event.position.x / zoom)
			frame -= AnimationHandler.warmup
			frame = clampi(frame, -AnimationHandler.warmup, AnimationHandler.end)
			AnimationHandler.current_frame = frame

func _draw() -> void:
	draw_line(Vector2(0, 0), Vector2(0, size.y), Color.WHITE)
	var start_frame: int = -AnimationHandler.warmup
	var end_frame: int = AnimationHandler.end
	
	if start_frame < 0:
		draw_line(Vector2(-start_frame * zoom, 0), Vector2(-start_frame * zoom, size.y), Color.WHITE)
	draw_line(Vector2((-start_frame + end_frame) * zoom, 0), Vector2((-start_frame + end_frame) * zoom, size.y), Color.WHITE)
	
	var frame_step: int = 1
	var step_size: float = frame_step * zoom
	while step_size < 10:
		frame_step *= 10
		step_size = frame_step * zoom
	
	var fontsize: int = 10
	
	var maxtext := TextLine.new()
	maxtext.add_string(str(-end_frame), get_theme_font(&""), 10)
	var max_text_width: float = maxtext.get_size().x
	var skip_labels: int = 1
	skip_labels = ceili(max_text_width / step_size)
	
	
	var frame: int = frame_step
	var label_idx: int = 1
	while frame < end_frame:
		draw_line(Vector2((-start_frame + frame) * zoom, 0), Vector2((-start_frame + frame) * zoom, size.y - fontsize), Color.DIM_GRAY)
		if label_idx % skip_labels == 0:
			var txt := TextLine.new()
			var strng: String = str(frame)
			txt.add_string(strng, get_theme_font(&""), 10)
			var width: float = txt.get_size().x
			var textpos := Vector2((-start_frame + frame) * zoom - width / 2, size.y)
			draw_string(get_theme_font(&""), textpos, strng, HORIZONTAL_ALIGNMENT_CENTER, -1, fontsize)
		frame += frame_step
		label_idx += 1
	
	frame = -frame_step
	label_idx = 1
	while frame > start_frame:
		draw_line(Vector2((-start_frame + frame) * zoom, 0), Vector2((-start_frame + frame) * zoom, size.y - fontsize), Color.DIM_GRAY)
		if label_idx % skip_labels == 0:
			var txt := TextLine.new()
			var strng: String = str(frame)
			txt.add_string(strng, get_theme_font(&""), 10)
			var width: float = txt.get_size().x
			var textpos := Vector2((-start_frame + frame) * zoom - width / 2, size.y)
			draw_string(get_theme_font(&""), textpos, strng, HORIZONTAL_ALIGNMENT_CENTER, -1, fontsize)
		frame -= frame_step
		label_idx += 1
	
	draw_line(Vector2((-start_frame + current_frame) * zoom, 0), Vector2((-start_frame + current_frame) * zoom, size.y - fontsize), Color.ORANGE, 3)
	
	if animation:
		for kf: PropertyAnimation.Keyframe in animation.keyframes:
			var pos := Vector2((-start_frame + kf.frame) * zoom, (size.y - fontsize) / 2) - kf_texture.get_size() / 2
			if current_frame == kf.frame:
				draw_texture(kf_texture_highlight, pos)
			else:
				draw_texture(kf_texture, pos)

func update_ui() -> void:
	custom_minimum_size.x = (AnimationHandler.end + AnimationHandler.warmup) * zoom
	warmup_editor.set_value_no_signal(AnimationHandler.warmup)
	length_editor.set_value_no_signal(AnimationHandler.end)
	queue_redraw()

func update_animation_list() -> void:
	var selected: int = animation_selector.get_selected_id()
	animation_selector.clear()
	for anim: PropertyAnimation in AnimationHandler.animations:
		animation_selector.add_item(anim.name)
	if selected >= 0 and selected < animation_selector.item_count:
		animation_selector.select(selected)
	else:
		animation_selector.select(animation_selector.item_count - 1)
		if animation_selector.item_count > 0:
			animation_selector.item_selected.emit(animation_selector.item_count - 1)
	
