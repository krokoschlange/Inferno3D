class_name ViewportOptions
extends MenuButton

signal pause_toggled(on: bool)
signal preview_toggled(on: bool)
signal render_mode_changed(mode: int)

enum MenuAction {
	PREVIEW,
	PAUSE,
	RENDER_SEPARATOR,
	RENDER_COMBINED,
	RENDER_ALBEDO,
	RENDER_EMISSION,
	RENDER_NORMAL,
	RENDER_VELOCITY,
}

@export var panel: StyleBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var popup: PopupMenu = get_popup()
	popup.add_check_item("Preview", MenuAction.PREVIEW)
	popup.add_check_item("Pause", MenuAction.PAUSE)
	popup.add_theme_stylebox_override("panel", panel)
	popup.add_separator("", MenuAction.RENDER_SEPARATOR)
	popup.add_radio_check_item("Combined", MenuAction.RENDER_COMBINED)
	popup.add_radio_check_item("Albedo", MenuAction.RENDER_ALBEDO)
	popup.add_radio_check_item("Emission", MenuAction.RENDER_EMISSION)
	popup.add_radio_check_item("Normal", MenuAction.RENDER_NORMAL)
	popup.add_radio_check_item("Velocity", MenuAction.RENDER_VELOCITY)
	
	popup.set_item_checked(MenuAction.RENDER_COMBINED, true)
	
	popup.id_pressed.connect(item_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func item_pressed(id: int) -> void:
	var popup: PopupMenu = get_popup()
	match id:
		MenuAction.PREVIEW:
			var on: bool = popup.is_item_checked(MenuAction.PREVIEW)
			on = not on
			popup.set_item_checked(MenuAction.PREVIEW, on)
			preview_toggled.emit(on)
			show_popup.call_deferred()
			popup.set_focused_item.call_deferred(MenuAction.PREVIEW)
		MenuAction.PAUSE:
			var on: bool = popup.is_item_checked(MenuAction.PAUSE)
			on = not on
			popup.set_item_checked(MenuAction.PAUSE, on)
			pause_toggled.emit(on)
			show_popup.call_deferred()
			popup.set_focused_item.call_deferred(MenuAction.PAUSE)
		MenuAction.RENDER_COMBINED:
			set_render_mode(0)
			render_mode_changed.emit(0)
		MenuAction.RENDER_ALBEDO:
			set_render_mode(1)
			render_mode_changed.emit(1)
		MenuAction.RENDER_EMISSION:
			set_render_mode(2)
			render_mode_changed.emit(2)
		MenuAction.RENDER_NORMAL:
			set_render_mode(3)
			render_mode_changed.emit(3)
		MenuAction.RENDER_VELOCITY:
			set_render_mode(4)
			render_mode_changed.emit(4)
		_:
			pass


func set_preview(on: bool) -> void:
	var popup: PopupMenu = get_popup()
	popup.set_item_checked(MenuAction.PREVIEW, on)

func set_pause(on: bool) -> void:
	var popup: PopupMenu = get_popup()
	popup.set_item_checked(MenuAction.PAUSE, on)

func set_render_mode(mode: int) -> void:
	var popup: PopupMenu = get_popup()
	for i: int in range(MenuAction.RENDER_COMBINED, MenuAction.RENDER_VELOCITY + 1):
		popup.set_item_checked(i, false)
	popup.set_item_checked(MenuAction.RENDER_COMBINED + mode, true)
