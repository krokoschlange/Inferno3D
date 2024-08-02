class_name RenderingSettings
extends Control

@export var smoke_sim: SmokeSim:
	set(value):
		smoke_sim = value
		update_ui()
@export var render_scene_vp: RenderSceneVP

@onready var resolution_editor: Vector2iEditor = $VBoxContainer/ResolutionEditor
@onready var offset_editor: Vector2Editor = $VBoxContainer/HBoxContainer/OffsetEditor
@onready var size_factor_editor: FloatEditor = $VBoxContainer/GridContainer3/SizeFactorEditor
@onready var smoke_color_editor: CustomColorPickerButton = $VBoxContainer/GridContainer/SmokeColorEditor
@onready var scatter_factor_editor: FloatEditor = $VBoxContainer/GridContainer/ScatterFactorEditor
@onready var emission_editor: FloatEditor = $VBoxContainer/GridContainer/EmissionEditor
@onready var light_dir_editor: Vector3Editor = $VBoxContainer/HBoxContainer2/LightDirEditor
@onready var light_color_editor: CustomColorPickerButton = $VBoxContainer/GridContainer2/LightColorEditor
@onready var ambient_color_editor: CustomColorPickerButton = $VBoxContainer/GridContainer2/AmbientColorEditor
@onready var normal_strength_editor: FloatEditor = $VBoxContainer/GridContainer4/NormalStrengthEditor
@onready var normal_smoothness_editor: FloatEditor = $VBoxContainer/GridContainer4/NormalSmoothnessEditor
@onready var velocity_strength_editor: FloatEditor = $VBoxContainer/GridContainer4/VelocityStrengthEditor


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resolution_editor.value_changed.connect(func (new_value: Vector2i) -> void: render_scene_vp.render_resolution = new_value)
	resolution_editor.x_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		var old_vec2: Vector2i = render_scene_vp.render_resolution
		old_vec2.x = old_value
		var new_vec2: Vector2i = render_scene_vp.render_resolution
		new_vec2.x = new_value
		EditHistory.submit_object_actions([render_scene_vp], "render_resolution", [old_vec2], [new_vec2], update_ui))
	resolution_editor.y_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		var old_vec2: Vector2i = render_scene_vp.render_resolution
		old_vec2.y = old_value
		var new_vec2: Vector2i = render_scene_vp.render_resolution
		new_vec2.y = new_value
		EditHistory.submit_object_actions([render_scene_vp], "render_resolution", [old_vec2], [new_vec2], update_ui))
	
	offset_editor.value_changed.connect(func (new_value: Vector2) -> void: render_scene_vp.render_offset = new_value)
	offset_editor.x_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		var old_vec2: Vector2 = render_scene_vp.render_offset
		old_vec2.x = old_value
		var new_vec2: Vector2 = render_scene_vp.render_offset
		new_vec2.x = new_value
		EditHistory.submit_object_actions([render_scene_vp], "render_offset", [old_vec2], [new_vec2], update_ui))
	offset_editor.y_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		var old_vec2: Vector2 = render_scene_vp.render_offset
		old_vec2.y = old_value
		var new_vec2: Vector2 = render_scene_vp.render_offset
		new_vec2.y = new_value
		EditHistory.submit_object_actions([render_scene_vp], "render_offset", [old_vec2], [new_vec2], update_ui))
	
	size_factor_editor.value_changed.connect(func (new_value: float) -> void: render_scene_vp.render_scale = new_value)
	size_factor_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		EditHistory.submit_object_actions([render_scene_vp], "render_scale", [old_value], [new_value], update_ui))
	
	smoke_color_editor.color_changed.connect(func (new_value: Color) -> void: smoke_sim.smoke_color = new_value)
	smoke_color_editor.action_complete.connect(func (new_color: Color, old_color: Color) -> void:
		EditHistory.submit_object_actions([smoke_sim], "smoke_color", [old_color], [new_color], update_ui))
	
	scatter_factor_editor.value_changed.connect(func (new_value: float) -> void: smoke_sim.scatter_factor = new_value)
	scatter_factor_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		EditHistory.submit_object_actions([smoke_sim], "scatter_factor", [old_value], [new_value], update_ui))
	
	emission_editor.value_changed.connect(func (new_value: float) -> void: smoke_sim.emission_intensity = new_value)
	emission_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		EditHistory.submit_object_actions([smoke_sim], "emission_intensity", [old_value], [new_value], update_ui))
	
	light_dir_editor.value_changed.connect(func (new_value: Vector3) -> void: smoke_sim.light_direction = new_value)
	light_dir_editor.x_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		var old_vec3: Vector3 = smoke_sim.light_direction
		old_vec3.x = old_value
		var new_vec3: Vector3 = smoke_sim.light_direction
		new_vec3.x = new_value
		EditHistory.submit_object_actions([smoke_sim], "light_direction", [old_vec3], [new_vec3], update_ui))
	light_dir_editor.y_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		var old_vec3: Vector3 = smoke_sim.light_direction
		old_vec3.y = old_value
		var new_vec3: Vector3 = smoke_sim.light_direction
		new_vec3.y = new_value
		EditHistory.submit_object_actions([smoke_sim], "light_direction", [old_vec3], [new_vec3], update_ui))
	light_dir_editor.z_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		var old_vec3: Vector3 = smoke_sim.light_direction
		old_vec3.z = old_value
		var new_vec3: Vector3 = smoke_sim.light_direction
		new_vec3.z = new_value
		EditHistory.submit_object_actions([smoke_sim], "light_direction", [old_vec3], [new_vec3], update_ui))
	
	light_color_editor.color_changed.connect(func (new_value: Color) -> void: smoke_sim.light_color = new_value)
	light_color_editor.action_complete.connect(func (new_color: Color, old_color: Color) -> void:
		EditHistory.submit_object_actions([smoke_sim], "light_color", [old_color], [new_color], update_ui))
		
	ambient_color_editor.color_changed.connect(func (new_value: Color) -> void: smoke_sim.ambient_light = new_value)
	ambient_color_editor.action_complete.connect(func (new_color: Color, old_color: Color) -> void:
		EditHistory.submit_object_actions([smoke_sim], "ambient_light", [old_color], [new_color], update_ui))
	
	normal_strength_editor.value_changed.connect(func (new_value: float) -> void: smoke_sim.normal_strength = new_value)
	normal_strength_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		EditHistory.submit_object_actions([smoke_sim], "normal_strength", [old_value], [new_value], update_ui))
	normal_smoothness_editor.value_changed.connect(func (new_value: float) -> void: smoke_sim.normal_smoothness = new_value)
	normal_smoothness_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		EditHistory.submit_object_actions([smoke_sim], "normal_smoothness", [old_value], [new_value], update_ui))
	velocity_strength_editor.value_changed.connect(func (new_value: float) -> void: smoke_sim.velocity_map_strength = new_value)
	velocity_strength_editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		EditHistory.submit_object_actions([smoke_sim], "velocity_map_strength", [old_value], [new_value], update_ui))


func update_ui() -> void:
	resolution_editor.set_value_no_signal(render_scene_vp.render_resolution)
	offset_editor.set_value_no_signal(render_scene_vp.render_offset)
	size_factor_editor.set_value_no_signal(render_scene_vp.render_scale)
	smoke_color_editor.color = smoke_sim.smoke_color
	scatter_factor_editor.set_value_no_signal(smoke_sim.scatter_factor)
	emission_editor.set_value_no_signal(smoke_sim.emission_intensity)
	light_dir_editor.set_value_no_signal(smoke_sim.light_direction)
	light_color_editor.color = smoke_sim.light_color
	ambient_color_editor.color = smoke_sim.ambient_light
	normal_strength_editor.set_value_no_signal(smoke_sim.normal_strength)
	normal_smoothness_editor.set_value_no_signal(smoke_sim.normal_smoothness)
	velocity_strength_editor.set_value_no_signal(smoke_sim.velocity_map_strength)
	
	$VBoxContainer/HBoxContainer/OffsetKF.connect_property(render_scene_vp, "render_offset", update_ui, "Rendering: Camera Offset")
	$VBoxContainer/GridContainer3/SizeFactorKF.connect_property(render_scene_vp, "render_scale", update_ui, "Rendering: Camera Scale")
	$VBoxContainer/GridContainer/SmokeColorKF.connect_property(smoke_sim, "smoke_color", update_ui, "Rendering: Smoke Color")
	$VBoxContainer/GridContainer/ScatterFactorKF.connect_property(smoke_sim, "scatter_factor", update_ui, "Rendering: Scatter Factor")
	$VBoxContainer/GridContainer/EmissionKF.connect_property(smoke_sim, "emission_intensity", update_ui, "Rendering: Emission")
	$VBoxContainer/HBoxContainer2/LightDirKF.connect_property(smoke_sim, "light_direction", update_ui, "Rendering: Light Direction")
	$VBoxContainer/GridContainer2/LightColorKF.connect_property(smoke_sim, "light_color", update_ui, "Rendering: Light")
	$VBoxContainer/GridContainer2/AmbientColorKF.connect_property(smoke_sim, "ambient_light", update_ui, "Rendering: Ambient Light")
