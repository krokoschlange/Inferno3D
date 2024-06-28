class_name ViewportOptions
extends MenuButton

signal pause_toggled(on: bool)
signal preview_toggled(on: bool)

enum MenuAction {
	PREVIEW,
	PAUSE,
}

@export var panel: StyleBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var popup: PopupMenu = get_popup()
	popup.add_check_item("Preview", MenuAction.PREVIEW)
	popup.add_check_item("Pause", MenuAction.PAUSE)
	popup.add_theme_stylebox_override("panel", panel)
	
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
		_:
			pass


func set_preview(on: bool) -> void:
	var popup: PopupMenu = get_popup()
	popup.set_item_checked(MenuAction.PREVIEW, on)

func set_pause(on: bool) -> void:
	var popup: PopupMenu = get_popup()
	popup.set_item_checked(MenuAction.PAUSE, on)
