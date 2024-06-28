class_name IntEditor
extends LineEdit

signal value_changed(new_value: int)
signal action_start()
signal action_complete(new_value: int, old_value: int)

@export var min_value: int = 0:
	set(val):
		min_value = val
		value = clampi(value, min_value, max_value)
@export var max_value: int = 10:
	set(val):
		max_value = val
		value = clampi(value, min_value, max_value)
@export var value: int = 0:
	set(val):
		value = clampi(val, min_value, max_value)
		text = str(value)
		if emit:
			value_changed.emit(value)
@export var drag_speed: float = 0.1

@onready var inc_button: Button = $IncButton
@onready var dec_button: Button = $DecButton

var emit: bool = true
var pressed: bool = false
var dragging: bool = false
var drag_start: Vector2
var drag_position: Vector2
var drag_value_start: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_submitted.connect(on_text_submitted)
	inc_button.pressed.connect(on_inc_button_pressed)
	dec_button.pressed.connect(on_dec_button_pressed)
	focus_exited.connect(on_focus_exited)
	gui_input.connect(on_gui_input)

func on_focus_exited() -> void:
	if not dragging:
		on_text_submitted(text)

func on_text_submitted(new_text: String) -> void:
	action_start.emit()
	var old_value: int = value
	value = new_text.to_int()
	if value != old_value:
		action_complete.emit(value, old_value)
	release_focus()

func on_inc_button_pressed() -> void:
	action_start.emit()
	var old_value: int = value
	value = value + 1
	if value != old_value:
		action_complete.emit(value, old_value)

func on_dec_button_pressed() -> void:
	action_start.emit()
	var old_value: int = value
	value = value - 1
	if value != old_value:
		action_complete.emit(value, old_value)

func on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			drag_start = event.position
			drag_position = drag_start
			drag_value_start = value
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			pressed = true
		elif not event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.warp_mouse(global_position + drag_start)
			if dragging:
				deselect()
				dragging = false
				if value != drag_value_start:
					action_complete.emit(value, drag_value_start)
			else:
				select_all()
			pressed = false
	elif event is InputEventMouseMotion and pressed:
		if not dragging:
			dragging = true
			action_start.emit()
		drag_position += event.relative
		var diff: Vector2 = drag_position - drag_start
		value = drag_value_start + (diff.x - diff.y) * drag_speed
		release_focus()
		deselect()


func set_value_no_signal(val: int) -> void:
	emit = false
	value = val
	emit = true
