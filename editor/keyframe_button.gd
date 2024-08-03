class_name KeyframeButton
extends TextureButton

@export var inactive_texture: Texture2D
@export var keyframe_texture: Texture2D
@export var active_texture: Texture2D

var object: Object
var property: String
var update_func: Callable
var animation_name: String

var animation: PropertyAnimation
var update_signal: Signal

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AnimationHandler.frame_changed.connect(update)
	toggled.connect(on_toogled)
	update()

func connect_property(obj: Object, prop: String, ufunc: Callable, anim_name: String) -> void:
	object = obj
	property = prop
	update_func = ufunc
	animation_name = anim_name
	update()

func update() -> void:
	if animation and update_signal and update_signal.is_connected(update_func):
		update_signal.disconnect(update_func)
	if not object or not property:
		return
	animation = AnimationHandler.get_animation(object, property)
	if not animation:
		set_pressed_no_signal(false)
		texture_normal = inactive_texture
		queue_redraw()
	else:
		var value: Variant = animation.get_keyframe(AnimationHandler.current_frame)
		update_signal = animation.value_changed
		update_signal.connect(update_func)
		if value != null:
			set_pressed_no_signal(true)
			texture_pressed = keyframe_texture
			queue_redraw()
		else:
			set_pressed_no_signal(false)
			texture_normal = active_texture
			queue_redraw()


func on_toogled(on: bool) -> void:
	if not object or not property:
		return
	if on:
		AnimationHandler.add_keyframe(object, property, animation_name)
		var frame: int = AnimationHandler.current_frame
		var value: Variant = object.get(property)
		EditHistory.submit_custom_actions([func () -> void:
			AnimationHandler.add_keyframe_at(object, property, frame, value, animation_name)],
			[func () -> void:
				AnimationHandler.remove_keyframe_at(object, property, frame)
				object.set(property, value)],
			func () -> void:
				update()
				if update_func:
					update_func.call(),
			[], [])
		update()
	else:
		var frame: int = AnimationHandler.current_frame
		var value: Variant = AnimationHandler.get_animation(object, property).get_keyframe(frame)
		AnimationHandler.remove_keyframe(object, property)
		EditHistory.submit_custom_actions([func () -> void:
				AnimationHandler.remove_keyframe_at(object, property, frame)],
			[func () -> void:
				AnimationHandler.add_keyframe_at(object, property, frame, value, animation_name)],
			func () -> void:
				update()
				if update_func:
					update_func.call(),
			[], [])
		update()
