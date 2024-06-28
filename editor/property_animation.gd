class_name PropertyAnimation
extends RefCounted

enum InterpolationMode {
	LINEAR,
	CONSTANT,
}

var keyframes: Array[Keyframe]
var mode: InterpolationMode

var object: Object
var property: String
var name: String

var update: Callable

func apply(frame: int) -> void:
	object.set(property, get_value(frame))
	if update:
		update.call()

func get_value(frame: int) -> Variant:
	if keyframes.is_empty():
		return
	if keyframes.size() == 1:
		return keyframes[0].value
	if frame < keyframes[0].frame:
		return keyframes[0].value
	var kf: int = 1
	while kf < keyframes.size():
		if frame < keyframes[kf].frame:
			break
		kf += 1
	kf -= 1
	if kf == keyframes.size() - 1:
		return keyframes[-1].value
	return interpolate(keyframes[kf], keyframes[kf + 1], frame)

func interpolate(kf1: Keyframe, kf2: Keyframe, frame: int) -> Variant:
	match mode:
		InterpolationMode.LINEAR:
			return interpolate_linear(kf1, kf2, frame)
		_:
			return 0

func interpolate_linear(kf1: Keyframe, kf2: Keyframe, frame: int) -> Variant:
	if typeof(kf1.value) != typeof(kf2.value):
		return
	var weight: float = remap(frame, kf1.frame, kf2.frame, 0, 1)
	if kf1.value is float:
		return lerpf(kf1.value, kf2.value, weight)
	elif kf1.value is int:
		return roundi(lerpf(kf1.value, kf2.value, weight))
	elif kf1.value is Vector3:
		var v1 := kf1.value as Vector3
		var v2 := kf2.value as Vector3
		return v1.lerp(v2, weight)
	elif  kf1.value is Vector2:
		var v1 := kf1.value as Vector2
		var v2 := kf2.value as Vector2
		return v1.lerp(v2, weight)
	elif  kf1.value is Color:
		var v1 := kf1.value as Color
		var v2 := kf2.value as Color
		return v1.lerp(v2, weight)
	return 0

func add_keyframe(frame: int, value: Variant) -> void:
	var kf := Keyframe.new()
	kf.frame = frame
	kf.value = value
	var index: int = 0
	while index < keyframes.size():
		var current_kf: Keyframe = keyframes[index]
		if frame < current_kf.frame:
			break
		elif frame == current_kf.frame:
			keyframes.remove_at(index)
			break
		index += 1
	keyframes.insert(index, kf)

func remove_keyframe(frame: int) -> void:
	for kf: Keyframe in keyframes:
		if kf.frame == frame:
			keyframes.erase(kf)
			return

func get_keyframe(frame: int) -> Variant:
	for kf: Keyframe in keyframes:
		if kf.frame == frame:
			return kf.value
	return null

class Keyframe:
	var frame: int
	var value: Variant
