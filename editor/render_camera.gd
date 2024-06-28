@tool
class_name RenderCamera
extends Camera3D

@export var size_factor: float = 1
@export var offset := Vector2(0, 0)

var aspect_ratio: float
var bounds_mesh := WireframeCube.new()

@onready var smoke_sim: SmokeSim = $"../SmokeSim"
@onready var bounds: MeshInstance3D = $Bounds

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bounds.mesh = bounds_mesh


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var domain_size: Vector3 = smoke_sim.grid_size * smoke_sim.resolution
	size = domain_size.y * size_factor
	position.x = domain_size.x / 2 + domain_size.x * offset.x
	position.y = domain_size.y / 2 + domain_size.y * offset.y
	position.z = domain_size.z + 1
	near = 0.5
	far = 1.5 + domain_size.z
	
	var height: float = size
	var width: float = height * aspect_ratio
	bounds.position.x = -width / 2
	bounds.position.y = -height / 2
	bounds.position.z = 0
	
	bounds_mesh.size = Vector3(width, height, 0.5)
