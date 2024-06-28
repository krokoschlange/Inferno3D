@tool
extends Node

signal frame_changed()
signal animation_ended()
signal animations_changed()

var animations: Array[PropertyAnimation]

var warmup: int = 10
var end: int = 100

var current_frame: int:
	set(value):
		if current_frame != value:
			current_frame = value
			frame_changed.emit()
			set_frame(current_frame)
var playing: bool

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if playing:
		current_frame = mini(current_frame + 1, end)
		if current_frame == end:
			playing = false
			animation_ended.emit()

func set_frame(frame: int) -> void:
	for animation: PropertyAnimation in animations:
		animation.apply(frame)

func add_keyframe(object: Object, property: String, update_func: Callable = func () -> void: pass, anim_name: String = "") -> void:
	var anim: PropertyAnimation = get_animation(object, property, true, update_func, anim_name)
	anim.add_keyframe(current_frame, object.get(property))
	set_frame(current_frame)
	animations_changed.emit()

func add_keyframe_at(object: Object, property: String, frame: int, value: Variant, update_func: Callable = func () -> void: pass, anim_name: String = "") -> void:
	var anim: PropertyAnimation = get_animation(object, property, true, update_func, anim_name)
	anim.add_keyframe(frame, value)
	set_frame(current_frame)
	animations_changed.emit()

func remove_keyframe(object: Object, property: String) -> void:
	var anim: PropertyAnimation = get_animation(object, property, true)
	if anim:
		anim.remove_keyframe(current_frame)
		if anim.keyframes.size() == 0:
			animations.erase(anim)
		set_frame(current_frame)
		animations_changed.emit()

func remove_keyframe_at(object: Object, property: String, frame: int) -> void:
	var anim: PropertyAnimation = get_animation(object, property, true)
	if anim:
		anim.remove_keyframe(frame)
		if anim.keyframes.size() == 0:
			animations.erase(anim)
		set_frame(current_frame)
		animations_changed.emit()

func get_animation(object: Object, property: String, create: bool = false, update_func: Callable = func () -> void: pass, anim_name: String = "") -> PropertyAnimation:
	for anim: PropertyAnimation in animations:
		if anim.object == object and anim.property == property:
			return anim
	if not create:
		return null
	var new_anim := PropertyAnimation.new()
	new_anim.object = object
	new_anim.property = property
	new_anim.update = update_func
	new_anim.name = anim_name
	animations.append(new_anim)
	animations_changed.emit()
	return new_anim

func get_animation_name(src: SmokeSource, property: String) -> String:
	match property:
		"position":
			return src.name + ": Position"
		"radius":
			return src.name + ": Radius"
		"edge":
			return src.name + ": Edge"
		"rate":
			return src.name + ": Smoke Rate"
		"fuel_rate":
			return src.name + ": Fuel Rate"
		"explode":
			return src.name + ": Explode"
		"velocity":
			return src.name + ": Velocity"
		"force_velocity":
			return src.name + ": Air Vel Factor"
		_:
			return "Unknown"

func update_animation_names() -> void:
	for anim: PropertyAnimation in animations:
		if anim.object is SmokeSource:
			anim.name = get_animation_name(anim.object, anim.property)
	animations_changed.emit()
