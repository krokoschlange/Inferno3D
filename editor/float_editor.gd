class_name FloatEditor
extends LineEdit

signal value_changed(new_value: float)
signal action_start()
signal action_complete(new_value: float, old_value: float)

@export var min_value: float = 0:
	set(val):
		min_value = val
		value = clampf(value, min_value, max_value)
@export var max_value: float = 1:
	set(val):
		max_value = val
		value = clampf(value, min_value, max_value)
@export var value: float = 0.0:
	set(val):
		value = clampf(val, min_value, max_value)
		var rounded: float = roundf(value * 10000.0) / 10000.0
		text = str(rounded)
		if emit:
			value_changed.emit(value)
@export var drag_speed: float = 0.01


var emit: bool = true
var pressed: bool = false
var dragging: bool = false
var drag_start: Vector2
var drag_start_value: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value = value
	text_submitted.connect(on_text_submitted)
	focus_exited.connect(on_focus_exited)
	gui_input.connect(on_gui_input)

func on_focus_exited() -> void:
	if not dragging:
		on_text_submitted(text)

func on_text_submitted(new_text: String) -> void:
	action_start.emit()
	var old_value: float = value
	value = new_text.to_float()
	if not is_equal_approx(value, old_value):
		action_complete.emit(value, old_value)
	release_focus()

func on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			drag_start = event.position
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			pressed = true
			drag_start_value = value
		elif not event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.warp_mouse(global_position + drag_start)
			if dragging:
				deselect()
				dragging = false
				if not is_equal_approx(value, drag_start_value):
					action_complete.emit(value, drag_start_value)
			else:
				select_all()
			pressed = false
	elif event is InputEventMouseMotion and pressed:
		if not dragging:
			dragging = true
			action_start.emit()
		var diff: float = event.relative.x - event.relative.y
		value += diff * drag_speed
		release_focus()
		deselect()


func set_value_no_signal(val: float) -> void:
	emit = false
	value = val
	emit = true
