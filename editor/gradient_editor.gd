class_name GradientEditor
extends MarginContainer

signal point_selected(point: int)
signal point_moved(point: int, pos: float)
signal action_start()
signal drag_ended()
signal point_added(point: int)
signal point_removed(point: int)

var texture: GradientTexture1D:
	set(value):
		texture = value
		texture_rect.texture = texture
var selected: int = 0
var dragging: bool = false
var was_dragging: bool = false

@onready var texture_rect: TextureRect = $TextureRect


func _draw() -> void:
	var grad: Gradient = texture.gradient
	for i: int in grad.get_point_count():
		var offset: float = grad.get_offset(i)
		var col: Color = grad.get_color(i)
		
		var center_x: float = texture_rect.size.x * offset + get_theme_constant("margin_left")
		var width: float = 10
		var rect := Rect2(center_x - width * 0.5, 0, width, size.y)
		draw_rect(rect, col, true, -1, false)
		draw_rect(rect, Color.BLACK, false, 2, true)
		var border_col := Color(0.6, 0.6, 0.6)
		if i == selected:
			border_col = Color.WHITE
		rect.position.x += 1
		rect.position.y += 1
		rect.size.x -= 2
		rect.size.y -= 2
		draw_rect(rect, border_col, false, 1, true)


func _gui_input(event: InputEvent) -> void:
	var grad: Gradient = texture.gradient
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			for i: int in grad.get_point_count():
				var offset: float = grad.get_offset(i)
				
				var center_x: float = texture_rect.size.x * offset + get_theme_constant("margin_left")
				var width: float = 12
				var rect := Rect2(center_x - width * 0.5, 0, width, size.y)
				
				if rect.has_point(event.position):
					selected = i
					queue_redraw()
					point_selected.emit(i)
					dragging = true
					return
			
			var offset: float = (event.global_position.x - texture_rect.global_position.x) / texture_rect.size.x
			if offset < 0.0 or offset > 1.0:
				return
			
			action_start.emit()
			grad.add_point(offset, Color.BLACK)
			var index: int = 0
			for i: int in grad.get_point_count():
				if is_equal_approx(grad.get_offset(i), offset):
					index = i
					break
			point_added.emit(index)
			selected = index
			point_selected.emit(selected)
			queue_redraw()
			
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragging = false
			if was_dragging:
				drag_ended.emit()
				was_dragging = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if grad.get_point_count() <= 1:
				return
			for i: int in grad.get_point_count():
				var offset: float = grad.get_offset(i)
				
				var center_x: float = texture_rect.size.x * offset + get_theme_constant("margin_left")
				var width: float = 10
				var rect := Rect2(center_x - width * 0.5, 0, width, size.y)
				
				if rect.has_point(event.position):
					action_start.emit()
					grad.remove_point(i)
					queue_redraw()
					point_removed.emit(i)
					selected = clampi(selected, 0, grad.get_point_count() - 1)
					point_selected.emit(selected)
					return
	elif event is InputEventMouseMotion:
		if dragging:
			if not was_dragging:
				action_start.emit()
			var offset: float = (event.global_position.x - texture_rect.global_position.x) / texture_rect.size.x
			offset = clampf(offset, 0, 1)
			move_point(selected, offset)
			was_dragging = true


func move_point(point: int, offset: float) -> int:
	var grad: Gradient = texture.gradient
	var color: Color = grad.get_color(point)
	grad.set_offset(point, offset)
	point_moved.emit(point, offset)
	queue_redraw()
	var move_selection: bool = point == selected
	for i: int in grad.get_point_count():
		if color.is_equal_approx(grad.get_color(i)) and is_equal_approx(offset, grad.get_offset(i)):
			if move_selection:
				selected = i
				point_selected.emit(selected)
			return i
	if move_selection:
		selected = 0
		point_selected.emit(selected)
	return 0
