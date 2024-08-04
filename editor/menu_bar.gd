extends MenuBar

enum FileAction {
	NEW = 0,
	LOAD = 1,
	SAVE = 2,
	SAVE_AS = 3
}

enum EditAction {
	UNDO = 0,
	REDO = 1,
}

@onready var file: PopupMenu = $File
@onready var edit: PopupMenu = $Edit

@onready var color_rect: RenderProgressPopup = $"../ColorRect"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	file.id_pressed.connect(file_pressed)
	file.add_item("New", FileAction.NEW, KEY_N | KEY_MASK_CTRL)
	file.add_item("Load", FileAction.LOAD, KEY_O | KEY_MASK_CTRL)
	file.add_item("Save", FileAction.SAVE, KEY_S | KEY_MASK_CTRL)
	file.add_item("Save As", FileAction.SAVE_AS, KEY_S | KEY_MASK_SHIFT | KEY_MASK_CTRL)
	
	edit.id_pressed.connect(edit_pressed)
	edit.add_item("Undo", EditAction.UNDO, KEY_Z | KEY_MASK_CTRL)
	edit.add_item("Redo", EditAction.REDO, KEY_Z | KEY_MASK_CTRL | KEY_MASK_SHIFT)
	edit.set_item_disabled(EditAction.UNDO, not EditHistory.has_undo())
	edit.set_item_disabled(EditAction.REDO, not EditHistory.has_redo())
	EditHistory.history_changed.connect(func () -> void:
		edit.set_item_disabled(EditAction.UNDO, not EditHistory.has_undo())
		edit.set_item_disabled(EditAction.REDO, not EditHistory.has_redo()))


#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("save", false, true):
		#save_file(false)
	#elif event.is_action_pressed("save_as", false, true):
		#save_file(true)


func file_pressed(id: int) -> void:
	if color_rect.is_visible_in_tree():
		return
	match id:
		FileAction.NEW:
			new_file()
		FileAction.LOAD:
			load_file()
		FileAction.SAVE:
			save_file(false)
		FileAction.SAVE_AS:
			save_file(true)
		_:
			pass

func new_file() -> void:
	AnimationHandler.clear()
	EditHistory.clear()
	get_tree().reload_current_scene()

func load_file() -> void:
	var dialog := FileDialog.new()
	add_child(dialog)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.use_native_dialog = true
	dialog.show()
	
	dialog.file_selected.connect(func (path: String) -> void: FileIO.read(path))

func save_file(new_path: bool) -> void:
	if not new_path and FileIO.last_file_path != "":
		FileIO.save("", true)
	else:
		var dialog := FileDialog.new()
		add_child(dialog)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		dialog.use_native_dialog = true
		dialog.show()
		
		dialog.file_selected.connect(func (path: String) -> void: FileIO.save(path))

func edit_pressed(id: int) -> void:
	if color_rect.is_visible_in_tree():
		return
	match id:
		EditAction.UNDO:
			EditHistory.undo()
			edit.set_item_disabled(EditAction.UNDO, not EditHistory.has_undo())
			edit.set_item_disabled(EditAction.REDO, not EditHistory.has_redo())
		EditAction.REDO:
			EditHistory.redo()
			edit.set_item_disabled(EditAction.UNDO, not EditHistory.has_undo())
			edit.set_item_disabled(EditAction.REDO, not EditHistory.has_redo())
		_:
			pass
