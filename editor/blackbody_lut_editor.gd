class_name BlackbodyLUTEditor
extends Control

signal gradient_changed(new_gradient: Gradient)
signal action_complete(new_gradient: Gradient, old_gradient: Gradient)

@export var lut := GradientTexture1D.new()

@onready var float_editor: FloatEditor = $GridContainer/FloatEditor
@onready var color_picker: CustomColorPickerButton = $GridContainer/CustomColorPickerButton
@onready var gradient_editor: GradientEditor = $GradientEditor

@export var temp_range: Vector2

var gradient: Gradient:
	set(value):
		lut.gradient = value.duplicate()
		update()
	get():
		return lut.gradient
var previous_gradient: Gradient

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gradient_editor.texture = lut
	gradient_editor.point_selected.connect(func (point: int) -> void:
		var offset: float = lut.gradient.get_offset(point)
		var temp: float = remap(offset, 0, 1, temp_range.x, temp_range.y)
		float_editor.set_value_no_signal(temp)
		color_picker.color = lut.gradient.get_color(point)
		)
	gradient_editor.point_moved.connect(func (point: int, offset: float) -> void:
		var temp: float = remap(offset, 0, 1, temp_range.x, temp_range.y)
		float_editor.set_value_no_signal(temp)
		gradient_changed.emit(gradient))
	
	
	gradient_editor.action_start.connect(func () -> void:
		previous_gradient = lut.gradient.duplicate())
	gradient_editor.drag_ended.connect(func () -> void:
		action_complete.emit(lut.gradient.duplicate(), previous_gradient))
	gradient_editor.point_added.connect(func (point: int) -> void:
		gradient_changed.emit(lut.gradient.duplicate())
		action_complete.emit(lut.gradient.duplicate(), previous_gradient))
	gradient_editor.point_removed.connect(func (point: int) -> void:
		gradient_changed.emit(lut.gradient.duplicate())
		action_complete.emit(lut.gradient.duplicate(), previous_gradient))
	
	float_editor.min_value = temp_range.x
	float_editor.max_value = temp_range.y
	
	float_editor.value_changed.connect(func (new_value: float) -> void:
		var offset: float = remap(new_value, temp_range.x, temp_range.y, 0, 1)
		gradient_editor.move_point(gradient_editor.selected, offset))
	float_editor.action_start.connect(func () -> void: previous_gradient = lut.gradient.duplicate())
	float_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		action_complete.emit(lut.gradient.duplicate(), previous_gradient))
	
	color_picker.color_changed.connect(func (new_color: Color) -> void:
		lut.gradient.set_color(gradient_editor.selected, new_color)
		gradient_editor.queue_redraw()
		gradient_changed.emit(gradient))
	
	color_picker.pressed.connect(func () -> void: previous_gradient = lut.gradient.duplicate())
	color_picker.action_complete.connect(func (new_color: Color, old_color: Color) -> void:
		action_complete.emit(lut.gradient.duplicate(), previous_gradient))


func update() -> void:
	gradient_editor.queue_redraw()
	gradient_editor.point_selected.emit(gradient_editor.selected)
