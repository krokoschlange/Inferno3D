class_name SourceSettings
extends VBoxContainer

@onready var position_editor: Vector3Editor = $HBoxContainer/PositionEditor
@onready var size_editor: FloatEditor = $SlidersA/SizeEditor
@onready var smooth_editor: FloatEditor = $SlidersA/SmoothEditor
@onready var rate_editor: FloatEditor = $SlidersA/RateEditor
@onready var fuel_rate_editor: FloatEditor = $SlidersA/FuelRateEditor
@onready var explode_editor: FloatEditor = $SlidersA/ExplodeEditor
@onready var velocity_editor: Vector3Editor = $HBoxContainer2/VelocityEditor
@onready var force_vel_editor: FloatEditor = $SlidersB/ForceVelEditor

var source: SmokeSource = null:
	set(value):
		source = value
		update_ui()
var selection: Array[SmokeSource]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_vec3_property("position", position_editor.x_editor, position_editor.y_editor, position_editor.z_editor)
	connect_float_property("radius", size_editor)
	connect_float_property("edge", smooth_editor)
	connect_float_property("rate", rate_editor)
	connect_float_property("fuel_rate", fuel_rate_editor)
	connect_float_property("explode", explode_editor)
	connect_vec3_property("velocity", velocity_editor.x_editor, velocity_editor.y_editor, velocity_editor.z_editor)
	connect_float_property("force_velocity", force_vel_editor)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_ui() -> void:
	if size_editor and source:
		show()
		position_editor.set_value_no_signal(source.position)
		size_editor.set_value_no_signal(source.radius)
		smooth_editor.set_value_no_signal(pow(source.edge * pow(2, 13) + 0.999, 1 / 20.0) - 1)
		rate_editor.set_value_no_signal(source.rate)
		fuel_rate_editor.set_value_no_signal(source.fuel_rate)
		explode_editor.set_value_no_signal(source.explode)
		velocity_editor.set_value_no_signal(source.velocity)
		force_vel_editor.set_value_no_signal(source.force_velocity)
		
		$HBoxContainer/PositionKF.connect_property(source, "position", update_ui, AnimationHandler.get_animation_name(source, "position"))
		$SlidersA/SizeKF.connect_property(source, "radius", update_ui, AnimationHandler.get_animation_name(source, "radius"))
		$SlidersA/SmoothKF.connect_property(source, "edge", update_ui, AnimationHandler.get_animation_name(source, "edge"))
		$SlidersA/RateKF.connect_property(source, "rate", update_ui, AnimationHandler.get_animation_name(source, "rate"))
		$SlidersA/FuelRateKF.connect_property(source, "fuel_rate", update_ui, AnimationHandler.get_animation_name(source, "fuel_rate"))
		$SlidersA/ExplodeKF.connect_property(source, "explode", update_ui, AnimationHandler.get_animation_name(source, "explode"))
		$HBoxContainer2/VelocityKF.connect_property(source, "velocity", update_ui, AnimationHandler.get_animation_name(source, "velocity"))
		$SlidersB/ForceVelKF.connect_property(source, "force_velocity", update_ui, AnimationHandler.get_animation_name(source, "force_velocity"))
	else:
		hide()


func connect_float_property(property: String, editor: FloatEditor) -> void:
	editor.value_changed.connect(func (new_value: float) -> void:
		for src: SmokeSource in selection:
			src.set(property, new_value)
			AnimationHandler.update_keyframe(src, property)
		)
	editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		var objs: Array[Object] = []
		var old_vals: Array[float] = []
		var new_vals: Array[float] = []
		for src: SmokeSource in selection:
			objs.append(src)
			old_vals.append(old_value)
			new_vals.append(new_value)
		EditHistory.submit_object_actions(objs, property, old_vals, new_vals, update_ui)
		)

func connect_vec3_property(property: String, x_editor: FloatEditor, y_editor: FloatEditor, z_editor: FloatEditor) -> void:
	x_editor.value_changed.connect(func (new_value: float) -> void:
		for src: SmokeSource in selection:
			var value := src.get(property) as Vector3
			value.x = new_value
			src.set(property, value)
			AnimationHandler.update_keyframe(src, property)
		)
	y_editor.value_changed.connect(func (new_value: float) -> void:
		for src: SmokeSource in selection:
			var value := src.get(property) as Vector3
			value.y = new_value
			src.set(property, value)
			AnimationHandler.update_keyframe(src, property)
		)
	z_editor.value_changed.connect(func (new_value: float) -> void:
		for src: SmokeSource in selection:
			var value := src.get(property) as Vector3
			value.z = new_value
			src.set(property, value)
			AnimationHandler.update_keyframe(src, property)
		)
	x_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		var objs: Array[Object] = []
		var old_vals: Array[Vector3] = []
		var new_vals: Array[Vector3] = []
		for src: SmokeSource in selection:
			objs.append(src)
			var value := src.get(property) as Vector3
			var old_vec3: Vector3 = value
			old_vec3.x = old_value
			old_vals.append(old_vec3)
			var new_vec3: Vector3 = value
			new_vec3.x = new_value
			new_vals.append(new_vec3)
		EditHistory.submit_object_actions(objs, property, old_vals, new_vals, update_ui))
	y_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		var objs: Array[Object] = []
		var old_vals: Array[Vector3] = []
		var new_vals: Array[Vector3] = []
		for src: SmokeSource in selection:
			objs.append(src)
			var value := src.get(property) as Vector3
			var old_vec3: Vector3 = value
			old_vec3.y = old_value
			old_vals.append(old_vec3)
			var new_vec3: Vector3 = value
			new_vec3.y = new_value
			new_vals.append(new_vec3)
		EditHistory.submit_object_actions(objs, property, old_vals, new_vals, update_ui))
	z_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		var objs: Array[Object] = []
		var old_vals: Array[Vector3] = []
		var new_vals: Array[Vector3] = []
		for src: SmokeSource in selection:
			objs.append(src)
			var value := src.get(property) as Vector3
			var old_vec3: Vector3 = value
			old_vec3.z = old_value
			old_vals.append(old_vec3)
			var new_vec3: Vector3 = value
			new_vec3.z = new_value
			new_vals.append(new_vec3)
		EditHistory.submit_object_actions(objs, property, old_vals, new_vals, update_ui))
