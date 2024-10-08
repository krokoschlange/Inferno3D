extends Node

signal history_changed()
signal history_jump()

var current_item: int
var history: Array[ActionGroup]
var max_length: int = 128

var saved_item: int = -1
var is_saved: bool = false

func has_undo() -> bool:
	return current_item < history.size()

func has_redo() -> bool:
	return current_item > 0

func clear() -> void:
	history.clear()
	current_item = 0
	saved_item = -1
	is_saved = false
	history_changed.emit()

func submit_object_actions(objects: Array[Object], property: String, old_values: Array, new_values: Array, update_ui: Callable, ) -> void:
	var redo_funcs: Array[Callable] = []
	var undo_funcs: Array[Callable] = []
	var frame: int = AnimationHandler.current_frame
	for i: int in objects.size():
		var obj: Object = objects[i]
		redo_funcs.append(func () -> void:
			obj.set(property, new_values[i])
			AnimationHandler.update_keyframe_at(obj, property, frame))
		undo_funcs.append(func () -> void:
			obj.set(property, old_values[i])
			AnimationHandler.update_keyframe_at(obj, property, frame))
	submit_custom_actions(redo_funcs, undo_funcs, update_ui)

func submit_custom_actions(redos: Array[Callable], undos: Array[Callable], update_ui: Callable, free_on_delete: Array[Object] = [], free_on_outdated: Array[Object] = []) -> void:
	var group := ActionGroup.new()
	group.object_actions = []
	for i: int in redos.size():
		var action := Action.new()
		action.redo_func = redos[i]
		action.undo_func = undos[i]
		group.object_actions.append(action)
	group.free_on_delete = free_on_delete
	group.free_on_outdated = free_on_outdated
	group.update_ui = update_ui
	add_action_group(group)

func add_action_group(group: ActionGroup) -> void:
	while current_item > 0:
		var outdated := history.pop_front() as ActionGroup
		for obj: Object in outdated.free_on_outdated:
			if obj is Node:
				obj.queue_free()
			else:
				obj.free()
		current_item -= 1
		saved_item -= 1
	history.push_front(group)
	while history.size() > max_length:
		var old := history.pop_back() as ActionGroup
		for obj: Object in old.free_on_delete:
			if obj is Node:
				obj.queue_free()
			else:
				obj.free()
	saved_item += 1
	history_changed.emit()

func redo() -> void:
	if current_item == 0:
		return
	current_item -= 1
	history[current_item].redo()
	history_jump.emit()

func undo() -> void:
	if current_item >= history.size():
		return
	history[current_item].undo()
	current_item += 1
	history_jump.emit()

func save_current() -> void:
	saved_item = current_item
	is_saved = true

class Action:
	var redo_func: Callable
	var undo_func: Callable
	
	func redo() -> void:
		redo_func.call()
	
	func undo() -> void:
		undo_func.call()

class ActionGroup:
	var object_actions: Array[Action]
	var free_on_delete: Array[Object]
	var free_on_outdated: Array[Object]
	var update_ui: Callable
	
	func redo() -> void:
		for action: Action in object_actions:
			action.redo()
		if update_ui:
			update_ui.call()
	
	func undo() -> void:
		for action: Action in object_actions:
			action.undo()
		if update_ui:
			update_ui.call()
