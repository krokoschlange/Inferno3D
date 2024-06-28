class_name MainEditor
extends Control

@onready var render_scene: RenderScene = $MarginContainer/TabContainer/Simulation/Simulation/HSplitContainer/Control/SubViewportContainer/SubViewport/RenderScene
@onready var sources_list: SourcesList = $MarginContainer/TabContainer/Simulation/Simulation/TabContainer/Sources/Sources/SourcesList
@onready var simulation: SimulationSettings = $MarginContainer/TabContainer/Simulation/Simulation/TabContainer/Simulation/Simulation
@onready var rendering: RenderingSettings = $MarginContainer/TabContainer/Simulation/Simulation/HSplitContainer/TabContainer/Rendering
@onready var sub_viewport_container: RenderSceneVP = $MarginContainer/TabContainer/Simulation/Simulation/HSplitContainer/Control/SubViewportContainer
@onready var sprite_sheet_generator: SpriteSheetGenerator = $"MarginContainer/TabContainer/Sprite Sheet/HSplitContainer/SpriteSheetGenerator"
@onready var progress: RenderProgressPopup = $ColorRect
@onready var source: SourceSettings = $MarginContainer/TabContainer/Simulation/Simulation/HSplitContainer/TabContainer/Source/Source

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render_scene.translation_gizmo.position_edited.connect(source.update_ui)
	render_scene.source_selected.connect(sources_list.select_source)
	
	sources_list.translation_gizmo = render_scene.translation_gizmo
	sources_list.source_settings = source
	sources_list.smoke_sim = render_scene.smoke_sim
	
	simulation.smoke_sim = render_scene.smoke_sim
	rendering.render_scene_vp = sub_viewport_container
	rendering.smoke_sim = render_scene.smoke_sim
	sprite_sheet_generator.smoke_sim = render_scene.smoke_sim
	sprite_sheet_generator.viewport = sub_viewport_container
	sprite_sheet_generator.progress = progress
	
	FileIO.render_scene = render_scene
	FileIO.render_scene_vp = sub_viewport_container
	FileIO.sprite_sheet_gen = sprite_sheet_generator
	FileIO.file_loaded.connect(update_ui)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_ui() -> void:
	sources_list.update_ui()
	simulation.update_ui()
	rendering.update_ui()

