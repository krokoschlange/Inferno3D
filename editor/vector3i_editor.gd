class_name Vector3iEditor
extends GridContainer

signal value_changed(new_value: Vector3i)
signal x_changed(new_value: int)
signal z_changed(new_value: int)
signal y_changed(new_value: int)

@export var min_value: Vector3i:
	set(value):
		min_value = value
		if x_editor:
			x_editor.min_value = value.x
			y_editor.min_value = value.y
			z_editor.min_value = value.z
@export var max_value: Vector3i:
	set(value):
		max_value = value
		if x_editor:
			x_editor.max_value = value.x
			y_editor.max_value = value.y
			z_editor.max_value = value.z
@export var value: Vector3i:
	get():
		if not x_editor:
			return Vector3i()
		return Vector3i(x_editor.value, y_editor.value, z_editor.value)
	set(val):
		if x_editor:
			x_editor.value = val.x
			y_editor.value = val.y
			z_editor.value = val.z

@onready var x_editor: IntEditor = $IntEditor
@onready var y_editor: IntEditor = $IntEditor2
@onready var z_editor: IntEditor = $IntEditor3


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	min_value = min_value
	max_value = max_value
	value = value
	x_editor.value_changed.connect(func (new_value: int) -> void:
		value_changed.emit(value)
		x_changed.emit(new_value))
	y_editor.value_changed.connect(func (new_value: int) -> void:
		value_changed.emit(value)
		y_changed.emit(new_value))
	z_editor.value_changed.connect(func (new_value: int) -> void:
		value_changed.emit(value)
		z_changed.emit(new_value))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_value_no_signal(val: Vector3i) -> void:
	x_editor.set_value_no_signal(val.x)
	y_editor.set_value_no_signal(val.y)
	z_editor.set_value_no_signal(val.z)
