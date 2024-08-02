class_name RenderScene
extends Node3D

signal source_selected(source: SmokeSource, add: bool)

@onready var orbit_camera: OrbitCamera = $OrbitCamera
@onready var camera_3d: RenderCamera = $RenderCam
@onready var bounds: MeshInstance3D = $SmokeSim/Bounds
@onready var smoke_sim: SmokeSim = $SmokeSim
@onready var translation_gizmo: TranslationGizmo = $TranslationGizmo
@onready var ray_cast: RayCast3D = $RayCast3D

@onready var albedo_vp: SubViewport = $AlbedoVP
@onready var emission_vp: SubViewport = $EmissionVP
@onready var normal_vp: SubViewport = $NormalVP
@onready var velocity_vp: SubViewport = $VelocityVP


var object_pick_handled: bool = false
var picked_object: CollisionObject3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	recenter_orbit_camera()
	translation_gizmo.drag_started.connect(on_object_pick_handled)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var new_object: CollisionObject3D = pick_object(event.position)
		if new_object != picked_object:
			if picked_object:
				picked_object.mouse_exited.emit()
			if new_object:
				new_object.mouse_entered.emit()
			picked_object = new_object
		if picked_object:
			picked_object.input_event.emit(get_viewport().get_camera_3d(), event, ray_cast.get_collision_point(), ray_cast.get_collision_normal(), ray_cast.get_collider_shape())
	if event is InputEventMouseButton:
		var object: CollisionObject3D = pick_object(event.position)
		if object:
			object.input_event.emit(get_viewport().get_camera_3d(), event, ray_cast.get_collision_point(), ray_cast.get_collision_normal(), ray_cast.get_collider_shape())
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			check_object_pick.call_deferred()
	elif event.is_action_pressed("recenter_camera"):
		orbit_camera.recenter(translation_gizmo.global_position)

func pick_object(screen_pos: Vector2) -> CollisionObject3D:
	var cam: Camera3D = get_viewport().get_camera_3d()
	var start: Vector3 = cam.project_ray_origin(screen_pos)
	var dir: Vector3 = cam.project_ray_normal(screen_pos)
	ray_cast.global_position = start
	ray_cast.target_position = dir.normalized() * 1000
	ray_cast.collision_mask = 2
	ray_cast.force_raycast_update()
	var collider := ray_cast.get_collider() as CollisionObject3D
	if collider:
		return collider
	ray_cast.collision_mask = 3
	ray_cast.force_raycast_update()
	collider = ray_cast.get_collider() as CollisionObject3D
	return collider
	

func on_object_pick_handled() -> void:
	object_pick_handled = true

func check_object_pick() -> void:
	if not object_pick_handled:
		source_selected.emit(null, false)
	object_pick_handled = false

func set_preview(on: bool) -> void:
	if on:
		camera_3d.current = true
		translation_gizmo.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		orbit_camera.set_current()
		translation_gizmo.process_mode = Node.PROCESS_MODE_INHERIT

func pause_simulation(pause: bool) -> void:
	smoke_sim.paused = pause

func set_gizmo_enabled(state: bool) -> void:
	var mode: Node.ProcessMode = Node.PROCESS_MODE_DISABLED
	if state:
		mode = Node.PROCESS_MODE_INHERIT
	
	translation_gizmo.process_mode = mode
	for child: Node in smoke_sim.get_children():
		if child is SmokeSource:
			var gizmo: SourceSelectionGizmo = child.gizmo
			gizmo.process_mode = mode

func show_bounds(on: bool) -> void:
	bounds.visible = on

func recenter_orbit_camera() -> void:
	orbit_camera.position = Vector3(smoke_sim.resolution) * smoke_sim.grid_size * 0.5
