@tool
class_name SmokeSource
extends Node3D

@export var rate: float = 0.0
@export var fuel_rate: float = 100.0
@export var radius: float = 1.0:
	set(value):
		radius = value
		if gizmo:
			gizmo.update()
@export var velocity: Vector3
@export var force_velocity: float
@export var explode: float = 0
@export_exp_easing("attenuation") var edge: float = 0.4058


var gizmo: SourceSelectionGizmo

func _ready() -> void:
	var gizmo_scene: PackedScene = load("res://editor/source_selection_gizmo.tscn")
	gizmo = gizmo_scene.instantiate()
	gizmo.source = self
	add_child(gizmo)
	var rs := get_parent().get_parent() as RenderScene
	if rs:
		gizmo.selected.connect(func () -> void: rs.source_selected.emit(self, Input.is_key_pressed(KEY_SHIFT)))
		gizmo.selected.connect(rs.on_object_pick_handled)


func clone() -> SmokeSource:
	var new := SmokeSource.new()
	new.name = name
	new.position = position
	new.rate = rate
	new.fuel_rate = fuel_rate
	new.radius = radius
	new.velocity = velocity
	new.force_velocity = force_velocity
	new.explode = explode
	return new
