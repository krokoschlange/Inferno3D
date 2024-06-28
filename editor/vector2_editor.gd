class_name Vector2Editor
extends GridContainer

signal value_changed(new_value: Vector2)

@export var min_value: Vector2:
	set(val):
		min_value = val
		if x_editor:
			x_editor.min_value = val.x
			y_editor.min_value = val.y
@export var max_value: Vector2:
	set(val):
		max_value = val
		if x_editor:
			x_editor.max_value = val.x
			y_editor.max_value = val.y
@export var default_value: Vector2
var value: Vector2:
	get():
		if not x_editor:
			return Vector2()
		return Vector2(x_editor.value, y_editor.value)
	set(val):
		if x_editor:
			x_editor.value = val.x
			y_editor.value = val.y

@onready var x_editor: FloatEditor = $FloatEditor
@onready var y_editor: FloatEditor = $FloatEditor2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	min_value = min_value
	max_value = max_value
	value = default_value
	x_editor.value_changed.connect(func (new_value: float) -> void: value_changed.emit(value))
	y_editor.value_changed.connect(func (new_value: float) -> void: value_changed.emit(value))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_value_no_signal(val: Vector2) -> void:
	x_editor.set_value_no_signal(val.x)
	y_editor.set_value_no_signal(val.y)
