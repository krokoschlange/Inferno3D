class_name SimulationSettings
extends VBoxContainer

@export var smoke_sim: SmokeSim:
	set(value):
		smoke_sim = value
		update_ui()

@onready var resolution_editor: Vector3iEditor = $ResolutionEditor
@onready var grid_size_editor: FloatEditor = $Simulation/GridSizeEditor
@onready var jacobi_editor: IntEditor = $Simulation/JacobiEditor
@onready var d_time_editor: FloatEditor = $Simulation/DTimeEditor
@onready var dissipation_editor: FloatEditor = $Simulation/DissipationEditor
@onready var vorticity_editor: FloatEditor = $Simulation/VorticityEditor
@onready var burn_rate_editor: FloatEditor = $Simulation/BurnRateEditor
@onready var smoke_rate_editor: FloatEditor = $Simulation/SmokeRateEditor
@onready var burn_temp_editor: FloatEditor = $Simulation/BurnTempEditor
@onready var cool_rate_editor: FloatEditor = $Simulation/CoolRateEditor
@onready var buoyancy_editor: FloatEditor = $Simulation/BuoyancyEditor
@onready var up_editor: Vector3Editor = $HBoxContainer/UpEditor


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resolution_editor.value_changed.connect(func (new_value: Vector3i) -> void: smoke_sim.resolution = new_value)
	resolution_editor.x_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		var old_vec3: Vector3i = smoke_sim.resolution
		old_vec3.x = old_value
		var new_vec3: Vector3i = smoke_sim.resolution
		new_vec3.x = new_value
		EditHistory.submit_object_actions([smoke_sim], "resolution", [old_vec3], [new_vec3], update_ui))
	resolution_editor.y_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		var old_vec3: Vector3i = smoke_sim.resolution
		old_vec3.y = old_value
		var new_vec3: Vector3i = smoke_sim.resolution
		new_vec3.y = new_value
		EditHistory.submit_object_actions([smoke_sim], "resolution", [old_vec3], [new_vec3], update_ui))
	resolution_editor.z_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		var old_vec3: Vector3i = smoke_sim.resolution
		old_vec3.z = old_value
		var new_vec3: Vector3i = smoke_sim.resolution
		new_vec3.z = new_value
		EditHistory.submit_object_actions([smoke_sim], "resolution", [old_vec3], [new_vec3], update_ui))
	
	connect_float_property("grid_size", grid_size_editor)
	jacobi_editor.value_changed.connect(func (new_value: int) -> void:
		smoke_sim.jacobi_iterations = new_value
		AnimationHandler.update_keyframe(smoke_sim, "jacobi_iterations"))
	jacobi_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		EditHistory.submit_object_actions([smoke_sim], "jacobi_iterations", [old_value], [new_value], update_ui))
	connect_float_property("dtime", d_time_editor)
	connect_float_property("dissipation_factor", dissipation_editor)
	connect_float_property("vorticity_confinement_factor", vorticity_editor)
	connect_float_property("burn_rate", burn_rate_editor)
	connect_float_property("smoke_rate", smoke_rate_editor)
	connect_float_property("burn_temp", burn_temp_editor)
	connect_float_property("cool_rate", cool_rate_editor)
	connect_float_property("buoyancy", buoyancy_editor)
	
	up_editor.value_changed.connect(func (new_value: Vector3) -> void: smoke_sim.up_vector = new_value)
	up_editor.x_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		var old_vec3: Vector3 = smoke_sim.up_vector
		old_vec3.x = old_value
		var new_vec3: Vector3 = smoke_sim.up_vector
		new_vec3.x = new_value
		EditHistory.submit_object_actions([smoke_sim], "up_vector", [old_vec3], [new_vec3], update_ui))
	up_editor.y_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		var old_vec3: Vector3 = smoke_sim.up_vector
		old_vec3.y = old_value
		var new_vec3: Vector3 = smoke_sim.up_vector
		new_vec3.y = new_value
		EditHistory.submit_object_actions([smoke_sim], "up_vector", [old_vec3], [new_vec3], update_ui))
	up_editor.z_editor.action_complete.connect(func (new_value: int, old_value: int) -> void:
		var old_vec3: Vector3 = smoke_sim.up_vector
		old_vec3.z = old_value
		var new_vec3: Vector3 = smoke_sim.up_vector
		new_vec3.z = new_value
		EditHistory.submit_object_actions([smoke_sim], "up_vector", [old_vec3], [new_vec3], update_ui))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_ui() -> void:
	resolution_editor.set_value_no_signal(smoke_sim.resolution)
	grid_size_editor.set_value_no_signal(smoke_sim.grid_size)
	jacobi_editor.set_value_no_signal(smoke_sim.jacobi_iterations)
	d_time_editor.set_value_no_signal(smoke_sim.dtime)
	dissipation_editor.set_value_no_signal(smoke_sim.dissipation_factor)
	vorticity_editor.set_value_no_signal(smoke_sim.vorticity_confinement_factor)
	burn_rate_editor.set_value_no_signal(smoke_sim.burn_rate)
	smoke_rate_editor.set_value_no_signal(smoke_sim.smoke_rate)
	burn_temp_editor.set_value_no_signal(smoke_sim.burn_temp)
	cool_rate_editor.set_value_no_signal(smoke_sim.cool_rate)
	buoyancy_editor.set_value_no_signal(smoke_sim.buoyancy)
	up_editor.set_value_no_signal(smoke_sim.up_vector)
	
	$Simulation/JacobiKF.connect_property(smoke_sim, "jacobi_iterations", update_ui, "Simulation: Jacobi Iterations")
	$Simulation/DTimeKF.connect_property(smoke_sim, "dtime", update_ui, "Simulation: Delta Time")
	$Simulation/DissipationKF.connect_property(smoke_sim, "dissipation_factor", update_ui, "Simulation: Dissipation")
	$Simulation/VorticityKF.connect_property(smoke_sim, "vorticity_confinement_factor", update_ui, "Simulation: Vorticity")
	$Simulation/BurnRateKF.connect_property(smoke_sim, "burn_rate", update_ui, "Simulation: Burn Rate")
	$Simulation/SmokeRateKF.connect_property(smoke_sim, "smoke_rate", update_ui, "Simulation: Smoke Rate")
	$Simulation/BurnTempKF.connect_property(smoke_sim, "burn_temp", update_ui, "Simulation: Burn Temp")
	$Simulation/CoolRateKF.connect_property(smoke_sim, "cool_rate", update_ui, "Simulation: Cool Rate")
	$Simulation/BuoyancyKF.connect_property(smoke_sim, "buoyancy", update_ui, "Simulation: Buoyancy")
	$HBoxContainer/UpKF.connect_property(smoke_sim, "up_vector", update_ui, "Simulation: Up Vector")

func connect_float_property(property: String, editor: FloatEditor) -> void:
	editor.value_changed.connect(func (new_value: float) -> void:
		smoke_sim.set(property, new_value)
		AnimationHandler.update_keyframe(smoke_sim, property))
	editor.action_complete.connect(func (new_value: float, old_value: float) -> void:
		EditHistory.submit_object_actions([smoke_sim], property, [old_value], [new_value], update_ui))
