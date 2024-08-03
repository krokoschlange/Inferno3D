class_name BlackbodyLUTEditor
extends Control


@export var lut: GradientTexture1D

@onready var float_editor: FloatEditor = $VBoxContainer/GridContainer/FloatEditor
@onready var color_picker: CustomColorPickerButton = $VBoxContainer/GridContainer/CustomColorPickerButton
@onready var gradient_editor: GradientEditor = $VBoxContainer/GradientEditor

@export var temp_range: Vector2


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
		float_editor.set_value_no_signal(temp))
	
	float_editor.min_value = temp_range.x
	float_editor.max_value = temp_range.y
	
	float_editor.value_changed.connect(func (new_value: float) -> void:
		var offset: float = remap(new_value, temp_range.x, temp_range.y, 0, 1)
		gradient_editor.move_point(gradient_editor.selected, offset))
	
	color_picker.color_changed.connect(func (new_color: Color) -> void:
		lut.gradient.set_color(gradient_editor.selected, new_color)
		gradient_editor.queue_redraw())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
