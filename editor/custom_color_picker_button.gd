class_name CustomColorPickerButton
extends ColorPickerButton

signal action_complete(new_color: Color, old_color: Color)

var previous_color: Color

func _ready() -> void:
	pressed.connect(func () -> void: previous_color = color)
	popup_closed.connect(func () -> void:
		if not color.is_equal_approx(previous_color):
			action_complete.emit(color, previous_color))
