extends Node

signal file_loaded()

var render_scene: RenderScene
var render_scene_vp: RenderSceneVP
var sprite_sheet_gen: SpriteSheetGenerator

var last_file_path: String

func save(filename: String, use_last_used_path: bool = false) -> void:
	var smoke_sim: SmokeSim = render_scene.smoke_sim
	var file := ConfigFile.new()
	
	file.set_value("Simulation", "resolution", smoke_sim.resolution)
	file.set_value("Simulation", "cell_size", smoke_sim.grid_size)
	file.set_value("Simulation", "jacobi_iterations", smoke_sim.jacobi_iterations)
	file.set_value("Simulation", "dtime", smoke_sim.dtime)
	file.set_value("Simulation", "dissipation_factor", smoke_sim.dissipation_factor)
	file.set_value("Simulation", "vorticity_confinement_factor", smoke_sim.vorticity_confinement_factor)
	file.set_value("Simulation", "burn_rate", smoke_sim.burn_rate)
	file.set_value("Simulation", "smoke_rate", smoke_sim.smoke_rate)
	file.set_value("Simulation", "burn_temp", smoke_sim.burn_temp)
	file.set_value("Simulation", "cool_rate", smoke_sim.cool_rate)
	file.set_value("Simulation", "buoyancy", smoke_sim.buoyancy)
	file.set_value("Simulation", "up_vector", smoke_sim.up_vector)
	
	file.set_value("Rendering", "resolution", render_scene_vp.render_resolution)
	file.set_value("Rendering", "render_offset", render_scene_vp.render_offset)
	file.set_value("Rendering", "render_scale", render_scene_vp.render_scale)
	file.set_value("Rendering", "smoke_color", smoke_sim.smoke_color)
	file.set_value("Rendering", "scatter_factor", smoke_sim.scatter_factor)
	file.set_value("Rendering", "emission_intensity", smoke_sim.emission_intensity)
	file.set_value("Rendering", "light_direction", smoke_sim.light_direction)
	file.set_value("Rendering", "light_color", smoke_sim.light_color)
	file.set_value("Rendering", "ambient_light", smoke_sim.ambient_light)
	file.set_value("Rendering", "normal_strength", smoke_sim.normal_strength)
	file.set_value("Rendering", "normal_smoothness", smoke_sim.normal_smoothness)
	file.set_value("Rendering", "velocity_map_strength", smoke_sim.velocity_map_strength)
	
	file.set_value("SpriteSheet", "grid", sprite_sheet_gen.grid_editor.value)
	file.set_value("SpriteSheet", "skip", sprite_sheet_gen.skip_editor.value)
	
	var source_idx: int = 0
	for child in smoke_sim.get_children():
		if not child is SmokeSource:
			continue
		var source := child as SmokeSource
		var section: String = "Source" + str(source_idx)
		file.set_value(section, "name", source.name)
		file.set_value(section, "position", source.position)
		file.set_value(section, "radius", source.radius)
		file.set_value(section, "edge", source.edge)
		file.set_value(section, "rate", source.rate)
		file.set_value(section, "fuel_rate", source.fuel_rate)
		file.set_value(section, "explode", source.explode)
		file.set_value(section, "velocity", source.velocity)
		source_idx += 1
	
	file.set_value("AnimationGlobal", "warmup", AnimationHandler.warmup)
	file.set_value("AnimationGlobal", "length", AnimationHandler.end)
	file.set_value("AnimationGlobal", "current", AnimationHandler.current_frame)
	
	var anim_idx: int = 0
	for anim: PropertyAnimation in AnimationHandler.animations:
		var section: String = "Animation" + str(anim_idx)
		if anim.object is SmokeSource:
			file.set_value(section, "object_type", "source")
			file.set_value(section, "object", anim.object.name)
		elif anim.object == smoke_sim:
			file.set_value(section, "object_type", "simulation")
		elif anim.object == render_scene_vp:
			file.set_value(section, "object_type", "viewport")
		file.set_value(section, "property", anim.property)
		file.set_value(section, "name", anim.name)
		file.set_value(section, "mode", anim.mode)
		var frames := PackedFloat32Array()
		var values := Array()
		for kf: PropertyAnimation.Keyframe in anim.keyframes:
			frames.append(kf.frame)
			values.append(kf.value)
		file.set_value(section, "frames", frames)
		file.set_value(section, "values", values)
		anim_idx += 1
	
	var path: String = filename
	if use_last_used_path:
		path = last_file_path
	last_file_path = path
	file.save(path)

func read(filename: String) -> void:
	var smoke_sim: SmokeSim = render_scene.smoke_sim
	var file := ConfigFile.new()
	file.load(filename)
	
	smoke_sim.resolution = file.get_value("Simulation", "resolution", Vector3i(128, 128, 128))
	smoke_sim.grid_size = file.get_value("Simulation", "grid_size", 0.1)
	smoke_sim.jacobi_iterations = file.get_value("Simulation", "jacobi_iterations", 20)
	smoke_sim.dtime = file.get_value("Simulation", "dtime", 0.016)
	smoke_sim.dissipation_factor = file.get_value("Simulation", "dissipation_factor", 0.2)
	smoke_sim.vorticity_confinement_factor = file.get_value("Simulation", "vorticity_confinement_factor", 0.15)
	smoke_sim.burn_rate = file.get_value("Simulation", "burn_rate", 0.9)
	smoke_sim.smoke_rate = file.get_value("Simulation", "smoke_rate", 5)
	smoke_sim.burn_temp = file.get_value("Simulation", "burn_temp", 5000)
	smoke_sim.cool_rate = file.get_value("Simulation", "cool_rate", 100)
	smoke_sim.buoyancy = file.get_value("Simulation", "buoyancy", 0.01)
	smoke_sim.up_vector = file.get_value("Simulation", "up_vector", Vector3(0, 1, 0))
	
	render_scene_vp.render_resolution = file.get_value("Rendering", "resolution", Vector2i(128, 128))
	render_scene_vp.render_offset = file.get_value("Rendering", "render_offset", Vector2(0, 0))
	render_scene_vp.render_scale = file.get_value("Rendering", "render_scale", 1)
	smoke_sim.smoke_color = file.get_value("Rendering", "smoke_color", Color.WHITE)
	smoke_sim.scatter_factor = file.get_value("Rendering", "scatter_factor", 0.5)
	smoke_sim.emission_intensity = file.get_value("Rendering", "emission_intensity", 0.3)
	smoke_sim.light_direction = file.get_value("Rendering", "light_direction", Vector3(0, -1, 0))
	smoke_sim.light_color = file.get_value("Rendering", "light_color", Color.WHITE)
	smoke_sim.ambient_light = file.get_value("Rendering", "ambient_light", Color(0.148, 0.148, 0.148, 1))
	smoke_sim.normal_strength = file.get_value("Rendering", "normal_strength", 1.0)
	smoke_sim.normal_smoothness = file.get_value("Rendering", "normal_smoothness", 1.0)
	smoke_sim.velocity_map_strength = file.get_value("Rendering", "velocity_map_strength", 1.0)
	
	sprite_sheet_gen.grid_editor.set_value_no_signal(file.get_value("SpriteSheet", "grid", Vector2i(1, 1)))
	sprite_sheet_gen.skip_editor.set_value_no_signal(file.get_value("SpriteSheet", "skip", 0))
	
	for child in smoke_sim.get_children():
		if not child is SmokeSource:
			continue
		smoke_sim.remove_child(child)
		child.queue_free()
	
	var source_idx: int = 0
	var section: String = "Source" + str(source_idx)
	while file.has_section(section):
		var source := SmokeSource.new()
		source.name = file.get_value(section, "name", "Source")
		
		source.position = file.get_value(section, "position", Vector3(smoke_sim.resolution) * smoke_sim.grid_size * Vector3(0.5, 0, 0.5))
		source.radius = file.get_value(section, "radius", 1)
		source.edge = file.get_value(section, "edge", 0.4058)
		source.rate = file.get_value(section, "rate", 0)
		source.fuel_rate = file.get_value(section, "fuel_rate", 100)
		source.explode = file.get_value(section, "explode", 0)
		source.velocity = file.get_value(section, "velocity", Vector3(0, 0, 0))
		
		smoke_sim.add_child(source, true)
		
		source_idx += 1
		section = "Source" + str(source_idx)
	
	AnimationHandler.clear()
	AnimationHandler.warmup = file.get_value("AnimationGlobal", "warmup", 10)
	AnimationHandler.end = file.get_value("AnimationGlobal", "length", 100)
	AnimationHandler.current_frame = file.get_value("AnimationGlobal", "current", 0)
	
	var anim_idx: int = 0
	section = "Animation" + str(anim_idx)
	while file.has_section(section):
		var obj: Variant
		var obj_type: String = file.get_value(section, "object_type", "")
		if obj_type == "source":
			var obj_name: String = file.get_value(section, "object", "")
			if not smoke_sim.has_node(obj_name):
				continue
			obj = smoke_sim.get_node(obj_name)
		#var 
		#AnimationHandler.add_keyframe_at(obj, , , , )
	
	last_file_path = filename
	
	EditHistory.clear()
	
	file_loaded.emit()
