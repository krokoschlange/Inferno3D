@tool
class_name SmokeSim
extends Node3D

@export var resolution := Vector3i(128, 128, 128):
	set(value):
		resolution = value
		_exit_tree()
		_enter_tree()
@export var grid_size: float = 0.1:
	set(value):
		grid_size = value
		update_grid_size()

@export var jacobi_iterations: int = 20

@export_range(0.0, 0.1, 0.001) var dtime: float = 0.016
@export var paused: bool = false
@export_range(0.0, 1.0, 0.001) var dissipation_factor: float = 0.200
@export var vorticity_confinement_factor: float = 0.2

@export_range(0.0, 1.0, 0.001) var burn_rate: float = 0.9
@export_range(0.0, 100.0, 0.001) var smoke_rate: float = 5
@export var max_temp: float = 10
@export var burn_temp: float = 5000
@export var cool_rate: float = 100
@export var buoyancy: float = 0.01
@export var up_vector: Vector3 = Vector3.UP

var rd: RenderingDevice

var linear_sampler_no_repeat: RID

var advect_pipe: ComputePipe
var divergence_pipe: ComputePipe
var gradient_subtract_pipe: ComputePipe
var jacobi_pipe: ComputePipe
var source_pipe: ComputePipe
var dissipate_pipe: ComputePipe
var copy_pipe: ComputePipe
var curl_pipe: ComputePipe
var vorticity_confinement_pipe: ComputePipe
var thermal_buoyancy_pipe: ComputePipe
var burn_pipe: ComputePipe

var velocity_tex: RID
var temp_rgba_tex: RID
var density_tex: RID
var temp_r_tex: RID
var divergence_tex: RID
var pressure_tex: RID
var curl_tex: RID
var temperature_tex: RID
var fuel_tex: RID

var volume := MeshInstance3D.new()
var fog_mat: ShaderMaterial = load("res://simulation/volumetric.tres")
var fog_mat_dens_tex := Texture3DRD.new()
var fog_mat_temp_tex := Texture3DRD.new()
var fog_mat_fuel_tex := Texture3DRD.new()
var light_node := DirectionalLight3D.new()

var smoke_color := Color.WHITE:
	set(value):
		smoke_color = value
		fog_mat.set_shader_parameter("smoke_color", smoke_color)
var scatter_factor: float = 0.5:
	set(value):
		scatter_factor = value
		fog_mat.set_shader_parameter("scatter_factor", scatter_factor)
var emission_intensity: float = 0.3:
	set(value):
		emission_intensity = value
		fog_mat.set_shader_parameter("emission_intensity", emission_intensity)
var light_direction := Vector3(0, -1, 0):
	set(value):
		light_direction = value
		
		var node_dir: Vector3 = light_direction
		if light_direction.length() <= 0.0001:
			node_dir = Vector3.DOWN
		var up := Vector3.UP
		if absf(up.dot(node_dir.normalized())) > 0.99:
			up = Vector3.LEFT
		light_node.basis = Basis.looking_at(node_dir, up)
		
var light_color := Color.WHITE:
	set(value):
		light_color = value
		fog_mat.set_shader_parameter("light_color", light_color)
var ambient_light := Color(0.148, 0.148, 0.148):
	set(value):
		ambient_light = value
		fog_mat.set_shader_parameter("ambient_light", ambient_light)

var frame_i: float

var bounds_mesh := WireframeCube.new()

@onready var bounds: MeshInstance3D = $Bounds


func _ready() -> void:
	print("ready")
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1, 1, 1)
	volume.mesh = mesh
	add_child(volume)
	volume.material_override = fog_mat
	bounds.mesh = bounds_mesh
	add_child(light_node)

func _process(delta: float) -> void:
	if not paused and dtime > 0:
		run()
	volume.owner = null
	fog_mat.set_shader_parameter("frame_i", frame_i)
	frame_i = frame_i + 1
	frame_i = fmod(frame_i, 1024)
	fog_mat.set_shader_parameter("light_dir", -light_direction)

func _enter_tree() -> void:
	print("creating simulation buffers")
	init_compute()
	init_textures()
	fog_mat_dens_tex.texture_rd_rid = density_tex
	fog_mat_temp_tex.texture_rd_rid = temperature_tex
	fog_mat_fuel_tex.texture_rd_rid = fuel_tex
	fog_mat.set_shader_parameter("density", fog_mat_dens_tex)
	fog_mat.set_shader_parameter("temperature", fog_mat_temp_tex)
	fog_mat.set_shader_parameter("fuel", fog_mat_fuel_tex)
	update_grid_size()

func _exit_tree() -> void:
	print("freeing simulation buffers")
	free_compute()
	free_textures()
	fog_mat_dens_tex.texture_rd_rid = RID()
	fog_mat_temp_tex.texture_rd_rid = RID()
	fog_mat_fuel_tex.texture_rd_rid = RID()

func update_grid_size() -> void:
	fog_mat.set_shader_parameter("size", Vector3(resolution) * grid_size)
	fog_mat.set_shader_parameter("step_size", (Vector3(resolution) * grid_size).length() / 500)
	fog_mat.set_shader_parameter("light_step_size", (Vector3(resolution) * grid_size).length() / 100)
	volume.custom_aabb = AABB(Vector3(0, 0, 0), Vector3(resolution) * grid_size)
	bounds_mesh.size = Vector3(resolution) * grid_size
	

func init_compute() -> void:
	rd = RenderingServer.get_rendering_device()
	
	var sampler_state := RDSamplerState.new()
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_BORDER
	sampler_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_BORDER
	sampler_state.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_BORDER
	linear_sampler_no_repeat = rd.sampler_create(sampler_state)
	
	advect_pipe = ComputePipe.new(rd, "res://simulation/advect.glsl")
	divergence_pipe = ComputePipe.new(rd, "res://simulation/divergence.glsl")
	gradient_subtract_pipe = ComputePipe.new(rd, "res://simulation/gradient_subtract.glsl")
	jacobi_pipe = ComputePipe.new(rd, "res://simulation/jacobi.glsl")
	source_pipe = ComputePipe.new(rd, "res://simulation/source.glsl")
	dissipate_pipe = ComputePipe.new(rd, "res://simulation/dissipate.glsl")
	copy_pipe = ComputePipe.new(rd, "res://simulation/copy.glsl")
	curl_pipe = ComputePipe.new(rd, "res://simulation/curl.glsl")
	vorticity_confinement_pipe = ComputePipe.new(rd, "res://simulation/vorticity_confinement.glsl")
	thermal_buoyancy_pipe = ComputePipe.new(rd, "res://simulation/thermal_buoyancy.glsl")
	burn_pipe = ComputePipe.new(rd, "res://simulation/burn.glsl")

func free_compute() -> void:
	advect_pipe = null
	divergence_pipe = null
	gradient_subtract_pipe = null
	jacobi_pipe = null
	source_pipe = null
	dissipate_pipe = null
	copy_pipe = null
	curl_pipe = null
	vorticity_confinement_pipe = null
	
	if linear_sampler_no_repeat.is_valid():
		rd.free_rid(linear_sampler_no_repeat)
		linear_sampler_no_repeat = RID()

func init_textures() -> void:
	var format := RDTextureFormat.new()
	format.width = resolution.x
	format.height = resolution.y
	format.depth = resolution.z
	format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	format.texture_type = RenderingDevice.TEXTURE_TYPE_3D
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT

	var view := RDTextureView.new()
	var data := PackedByteArray()
	data.resize(resolution.x * resolution.y * resolution.z * 16)
	data.fill(0)
	velocity_tex = rd.texture_create(format, view, [data])
	temp_rgba_tex = rd.texture_create(format, view, [data])
	curl_tex = rd.texture_create(format, view, [data])
	
	data.resize(resolution.x * resolution.y * resolution.z * 4)
	format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	density_tex = rd.texture_create(format, view, [data])
	temp_r_tex = rd.texture_create(format, view, [data])
	divergence_tex = rd.texture_create(format, view, [data])
	pressure_tex = rd.texture_create(format, view, [data])
	temperature_tex = rd.texture_create(format, view, [data])
	fuel_tex = rd.texture_create(format, view, [data])

func clear_simulation() -> void:
	var data := PackedByteArray()
	data.resize(resolution.x * resolution.y * resolution.z * 16)
	data.fill(0)
	rd.texture_update(velocity_tex, 0, data)
	rd.texture_update(temp_rgba_tex, 0, data)
	rd.texture_update(curl_tex, 0, data)
	data.resize(resolution.x * resolution.y * resolution.z * 4)
	rd.texture_update(density_tex, 0, data)
	rd.texture_update(temp_r_tex, 0, data)
	rd.texture_update(divergence_tex, 0, data)
	rd.texture_update(pressure_tex, 0, data)
	rd.texture_update(temperature_tex, 0, data)
	rd.texture_update(fuel_tex, 0, data)

func free_textures() -> void:
	if velocity_tex.is_valid():
		rd.free_rid(velocity_tex)
		velocity_tex = RID()
	if temp_rgba_tex.is_valid():
		rd.free_rid(temp_rgba_tex)
		temp_rgba_tex = RID()
	if density_tex.is_valid():
		rd.free_rid(density_tex)
		density_tex = RID()
	if temp_r_tex.is_valid():
		rd.free_rid(temp_r_tex)
		temp_r_tex = RID()
	if divergence_tex.is_valid():
		rd.free_rid(divergence_tex)
		divergence_tex = RID()
	if pressure_tex.is_valid():
		rd.free_rid(pressure_tex)
		pressure_tex = RID()
	if curl_tex.is_valid():
		rd.free_rid(curl_tex)
		curl_tex = RID()
	if temperature_tex.is_valid():
		rd.free_rid(temperature_tex)
		temperature_tex = RID()
	if fuel_tex.is_valid():
		rd.free_rid(fuel_tex)
		fuel_tex = RID()

func run() -> void:
	advect(velocity_tex, velocity_tex, temp_rgba_tex, dtime)
	copy(temp_rgba_tex, velocity_tex)
	
	burn(fuel_tex, density_tex, temperature_tex, dtime)
	
	curl(velocity_tex, curl_tex)
	vorticity_confinement(curl_tex, velocity_tex)
	
	thermal_buoyancy(velocity_tex, temperature_tex, dtime)
	
	divergence(velocity_tex, divergence_tex)
	
	for i in jacobi_iterations:
		jacobi(pressure_tex, divergence_tex, temp_r_tex, -grid_size * grid_size, 1.0 / 6, i == 0)
		copy(temp_r_tex, pressure_tex)
	
	gradient_subtract(pressure_tex, velocity_tex)
	
	advect(velocity_tex, density_tex, temp_r_tex, dtime)
	copy(temp_r_tex, density_tex)
	advect(velocity_tex, temperature_tex, temp_r_tex, dtime)
	copy(temp_r_tex, temperature_tex)
	advect(velocity_tex, fuel_tex, temp_r_tex, dtime)
	copy(temp_r_tex, fuel_tex)
	
	dissipate(density_tex, dtime)
	
	sources(density_tex, fuel_tex, velocity_tex, dtime)

func advect(velocity: RID, field: RID, new_field: RID, step: float) -> void:
	var params := PackedFloat32Array()
	params.append(step)
	params.append(1 / grid_size)
	params.append(0)
	params.append(0)
	
	var vel_uni: RDUniform = sampler_uni(0, velocity)
	var old_field_uni: RDUniform = sampler_uni(1, field)
	var new_field_uni: RDUniform = image_uni(2, new_field)
	advect_pipe.update_params(params)
	var param_uni: RDUniform = param_bfr_uni(3, advect_pipe)
	advect_pipe.run(resolution, [vel_uni, old_field_uni, new_field_uni, param_uni])

func divergence(field: RID, div: RID) -> void:
	var params := PackedFloat32Array()
	params.append(0.5 / grid_size)
	params.append(0)
	params.append(0)
	params.append(0)
	
	var field_uni: RDUniform = sampler_uni(0, field)
	var div_uni: RDUniform = image_uni(1, div)
	divergence_pipe.update_params(params)
	var param_uni: RDUniform = param_bfr_uni(2, divergence_pipe)

	divergence_pipe.run(resolution, [field_uni, div_uni, param_uni])

func gradient_subtract(pressure: RID, vel: RID) -> void:
	var params := PackedFloat32Array()
	params.append(0.5 / grid_size)
	params.append(0)
	params.append(0)
	params.append(0)
	
	var pressure_uni: RDUniform = sampler_uni(0, pressure)
	var vel_uni: RDUniform = image_uni(1, vel)
	gradient_subtract_pipe.update_params(params)
	var param_uni: RDUniform = param_bfr_uni(2, gradient_subtract_pipe)
	
	gradient_subtract_pipe.run(resolution, [pressure_uni, vel_uni, param_uni])

func jacobi(x: RID, b: RID, f: RID, alpha: float, beta: float, clear_x: bool) -> void:
	var params := PackedFloat32Array()
	params.append(alpha)
	params.append(beta)
	params.append(1.0 if clear_x else 0.0)
	params.append(0)
	
	var x_uni: RDUniform = sampler_uni(0, x)
	var b_uni: RDUniform = sampler_uni(1, b)
	var f_uni: RDUniform = image_uni(2, f)
	jacobi_pipe.update_params(params)
	var param_uni: RDUniform = param_bfr_uni(3, jacobi_pipe)
	
	jacobi_pipe.run(resolution, [x_uni, b_uni, f_uni, param_uni])

func source(src: SmokeSource, density: RID, fuel: RID, velocity: RID, step: float) -> void:
	var source_vel: Vector3 = src.transform.basis * src.velocity
	
	var params := PackedFloat32Array()
	params.append(src.position.x)
	params.append(src.position.y)
	params.append(src.position.z)
	params.append(0)
	params.append(source_vel.x)
	params.append(source_vel.y)
	params.append(source_vel.z)
	params.append(0)
	params.append(src.radius)
	var src_vol: float = src.radius * src.radius * src.radius * PI * 4.0 / 3.0
	params.append(src.rate / src_vol * step)
	params.append(src.fuel_rate / src_vol * step)
	params.append(src.explode)
	params.append(grid_size)
	params.append(src.edge)
	params.append(src.force_velocity)
	params.append(0)
	
	var dens_uni: RDUniform = image_uni(0, density)
	var fuel_uni: RDUniform = image_uni(1, fuel)
	var vel_uni: RDUniform = image_uni(2, velocity)
	source_pipe.update_params(params)
	var param_uni: RDUniform = param_bfr_uni(3, source_pipe)
	
	source_pipe.run(resolution, [dens_uni, fuel_uni, vel_uni, param_uni])

func sources(density: RID, fuel: RID, velocity: RID, step: float) -> void:
	for child in get_children():
		if child is SmokeSource and child.is_visible():
			source(child, density, fuel, velocity, step)

func dissipate(field: RID, step: float) -> void:
	var params := PackedFloat32Array()
	params.append(pow(dissipation_factor, step))
	params.append(0)
	params.append(0)
	params.append(0)
	
	var field_uni: RDUniform = image_uni(0, field)
	dissipate_pipe.update_params(params)
	var param_uni: RDUniform = param_bfr_uni(1, dissipate_pipe)
	
	dissipate_pipe.run(resolution, [field_uni, param_uni])

func copy(src: RID, target: RID) -> void:
	var source_uni: RDUniform = sampler_uni(0, src)
	var target_uni: RDUniform = image_uni(1, target)
	
	copy_pipe.run(resolution, [source_uni, target_uni])

func curl(field: RID, crl: RID) -> void:
	var params := PackedFloat32Array()
	params.append(0.5 / grid_size)
	params.append(0)
	params.append(0)
	params.append(0)
	
	var field_uni: RDUniform = sampler_uni(0, field)
	var curl_uni: RDUniform = image_uni(1, crl)
	curl_pipe.update_params(params)
	var param_uni: RDUniform = param_bfr_uni(2, curl_pipe)
	
	curl_pipe.run(resolution, [field_uni, curl_uni, param_uni])

func vorticity_confinement(crl: RID, vel: RID) -> void:
	var params := PackedFloat32Array()
	params.append(0.5 / grid_size)
	params.append(vorticity_confinement_factor)
	params.append(0)
	params.append(0)
	
	var curl_uni: RDUniform = sampler_uni(0, crl)
	var vel_uni: RDUniform = image_uni(1, vel)
	vorticity_confinement_pipe.update_params(params)
	var param_uni: RDUniform = param_bfr_uni(2, vorticity_confinement_pipe)
	
	vorticity_confinement_pipe.run(resolution, [curl_uni, vel_uni, param_uni])

func thermal_buoyancy(vel: RID, temperature: RID, step: float) -> void:
	var params := PackedFloat32Array()
	var norm_up: Vector3 = up_vector.normalized()
	params.append(norm_up.x)
	params.append(norm_up.y)
	params.append(norm_up.z)
	params.append(0)
	params.append(step)
	params.append(buoyancy)
	params.append(0)
	params.append(0)
	
	var vel_uni: RDUniform = image_uni(0, vel)
	var temp_uni: RDUniform = sampler_uni(1, temperature)
	thermal_buoyancy_pipe.update_params(params)
	var param_uni: RDUniform = param_bfr_uni(2, thermal_buoyancy_pipe)
	
	thermal_buoyancy_pipe.run(resolution, [vel_uni, temp_uni, param_uni])

func burn(fuel: RID, density:RID, temperature: RID, step: float) -> void:
	var params := PackedFloat32Array()
	params.append(max_temp)
	params.append(burn_temp)
	params.append(cool_rate * step)
	params.append(pow(1 - burn_rate, step))
	params.append(smoke_rate)
	params.append(0)
	params.append(0)
	params.append(0)
	
	var fuel_uni: RDUniform = image_uni(0, fuel)
	var temp_uni: RDUniform = image_uni(1, temperature)
	var dens_uni: RDUniform = image_uni(2, density)
	burn_pipe.update_params(params)
	var param_uni: RDUniform = param_bfr_uni(3, burn_pipe)
	
	burn_pipe.run(resolution, [fuel_uni, temp_uni, dens_uni, param_uni])

func sampler_uni(binding: int, rid: RID) -> RDUniform:
	var uni := RDUniform.new()
	uni.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uni.binding = binding
	uni.add_id(linear_sampler_no_repeat)
	uni.add_id(rid)
	return uni

func image_uni(binding: int, rid: RID) -> RDUniform:
	var uni := RDUniform.new()
	uni.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uni.binding = binding
	uni.add_id(rid)
	return uni

func param_bfr_uni(binding: int, pipe: ComputePipe) -> RDUniform:
	var uni := RDUniform.new()
	uni.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	uni.binding = binding
	uni.add_id(pipe.param_bfr)
	return uni

class ComputePipe extends RefCounted:
	var rd: RenderingDevice
	var shader: RID
	var pipe: RID
	var param_bfr: RID
	
	func _init(r: RenderingDevice, path: String) -> void:
		rd = r
		var file: RDShaderFile = load(path)
		shader = rd.shader_create_from_spirv(file.get_spirv())
		pipe = rd.compute_pipeline_create(shader)
	
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			rd.free_rid(shader)
			#rd.free_rid(pipe)
			if param_bfr.is_valid():
				rd.free_rid(param_bfr)
	
	func run(resolution: Vector3i, uniforms: Array[RDUniform]) -> void:
		var groups: Vector3i = (resolution + Vector3i(7, 7, 7)) / 8
		var list: int = rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(list, pipe)
		var set0: RID = UniformSetCacheRD.get_cache(shader, 0, uniforms)
		rd.compute_list_bind_uniform_set(list, set0, 0)
		rd.compute_list_dispatch(list, groups.x, groups.y, groups.z)
		rd.compute_list_end()
	
	func update_params(values: PackedFloat32Array) -> void:
		if not param_bfr.is_valid():
			param_bfr = rd.uniform_buffer_create(values.size() * 4, values.to_byte_array())
		else:
			rd.buffer_update(param_bfr, 0, values.size() * 4, values.to_byte_array())
	
