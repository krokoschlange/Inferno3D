class_name SourcesList
extends Tree

enum MenuAction {
	DELETE = 0,
	RENAME = 1,
	DUPLICATE = 2,
}

var selection: Array[SmokeSource] = []

var source_settings: SourceSettings:
	set(value):
		source_settings = value
		if source_settings:
			source_settings.selection = selection
var translation_gizmo: TranslationGizmo:
	set(value):
		translation_gizmo = value
		if translation_gizmo:
			translation_gizmo.selection = selection

@onready var menu: PopupMenu = $PopupMenu
@onready var delete_confirmation_dialog: ConfirmationDialog = $DeleteConfirmationDialog

var smoke_sim: SmokeSim:
	set(value):
		smoke_sim = value
		update_ui()
		if sources.keys().size() > 0:
			select_source(sources.values()[0], false)

var sources: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multi_selected.connect(on_multi_selected)
	item_edited.connect(on_item_edited)
	nothing_selected.connect(on_nothing_selected)
	
	menu.add_item("Delete", MenuAction.DELETE, KEY_DELETE)
	menu.add_item("Rename", MenuAction.RENAME, KEY_F2)
	menu.add_item("Duplicate", MenuAction.DUPLICATE, KEY_D | KEY_MASK_CTRL)
	menu.id_pressed.connect(on_menu_id_pressed)
	
	delete_confirmation_dialog.confirmed.connect(remove_selected)

func _input(event: InputEvent) -> void:
	if event.is_pressed() and menu.activate_item_by_event(event):
		return

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MASK_RIGHT and event.pressed:
			menu.position = event.global_position
			menu.show()
			accept_event()

func update_ui() -> void:
	sources.clear()
	clear()
	selection.clear()
	source_settings.source = null
	var root: TreeItem = create_item()
	for child in smoke_sim.get_children():
		if child is SmokeSource:
			var item: TreeItem = create_item(root)
			item.set_text(0, child.name)
			sources[item] = child

func update_names() -> void:
	var items: Array[TreeItem] = get_root().get_children()
	
	var idx: int = 0
	for child in smoke_sim.get_children():
		if child is SmokeSource:
			items[idx].set_text(0, child.name)
			idx += 1
	AnimationHandler.update_animation_names()

func on_multi_selected(item: TreeItem, column: int, selected: bool) -> void:
	if not selected:
		return
	for it: TreeItem in sources:
		if not sources[it] in selection:
			it.set_editable(0, false)
	update_selection.call_deferred()
	source_settings.source = sources[get_selected()]

func on_nothing_selected() -> void:
	for it: TreeItem in sources:
		it.set_editable(0, false)
	deselect_all()
	source_settings.source = null
	update_selection()

func update_selection() -> void:
	var it: TreeItem = get_next_selected(null)
	selection.clear()
	while it != null:
		it.set_editable.call_deferred(0, true)
		selection.append(sources[it])
		it = get_next_selected(it)
	update_source_gizmos()

func on_item_edited() -> void:
	var source: SmokeSource = sources[get_edited()]
	var old_name: String = source.name
	source.name = get_edited().get_text(0)
	source_settings.update_ui()
	EditHistory.submit_object_actions([source], "name", [old_name], [source.name], update_names)
	AnimationHandler.update_animation_names()

func remove_source(item: TreeItem) -> void:
	for key: TreeItem in sources:
		if key == item:
			smoke_sim.remove_child(sources[key])
			#sources[key].queue_free()
			sources.erase(key)

func remove_source_object(src: SmokeSource) -> void:
	for key: TreeItem in sources:
		if sources[key] == src:
			smoke_sim.remove_child(sources[key])
			sources.erase(key)
	source_settings.source = null
	update_ui.call_deferred()

func _on_add_source_pressed() -> void:
	var source := SmokeSource.new()
	source.name = "Source"
	add_source(source)
	source.position = Vector3(smoke_sim.resolution) * smoke_sim.grid_size * Vector3(0.5, 0, 0.5)
	update_ui.call_deferred()
	select_source.call_deferred(source, false)
	EditHistory.submit_custom_actions([func () -> void: add_source(source)], [func () -> void: remove_source_object(source)], update_ui, [], [source])

func add_source(src: SmokeSource, idx: int = -1) -> void:
	smoke_sim.add_child(src, true)
	smoke_sim.move_child(src, idx)
	select_source.call_deferred(src, false)

func on_menu_id_pressed(id: int) -> void:
	if not is_visible_in_tree():
		return
	match id:
		MenuAction.DELETE:
			if get_selected():
				delete_confirmation_dialog.show()
		MenuAction.RENAME:
			var item: TreeItem = get_selected()
			if item:
				item.set_editable(0, true)
				edit_selected(true)
		MenuAction.DUPLICATE:
			var it: TreeItem = get_next_selected(null)
			if not it:
				return
			var new_selection: Array[SmokeSource] = []
			while it != null:
				it.set_editable.call_deferred(0, true)
				var source: SmokeSource = sources[it]
				var new: SmokeSource = source.clone()
				new_selection.append(new)
				smoke_sim.add_child(new, true)
				it = get_next_selected(it)
			update_ui()
			deselect_all()
			for key: TreeItem in sources:
				if sources[key] in new_selection:
					key.select(0)
					key.set_editable(0, true)
			update_source_gizmos()
			source_settings.source = new_selection[-1]
			selection.clear()
			selection.append_array(new_selection)
			
			var free_on_outdated: Array[Object] = []
			free_on_outdated.assign(new_selection)
			EditHistory.submit_custom_actions([func () -> void:
				for source: SmokeSource in new_selection:
					add_source(source)
				], [func () -> void:
				for source: SmokeSource in new_selection:
					remove_source_object(source)], update_ui, [], free_on_outdated)
		_:
			pass

func select_source(source: SmokeSource, add: bool) -> void:
	if not add or not source:
		deselect_all()
	for key: TreeItem in sources:
		if sources[key] == source:
			key.select(0)
	update_selection()
	source_settings.source = source

func update_source_gizmos() -> void:
	for key: TreeItem in sources:
		var item := key as TreeItem
		var source: SmokeSource = sources[key]
		var gizmo: SourceSelectionGizmo = source.gizmo
		gizmo.is_selected = item.is_selected(0)

func remove_selected() -> void:
	var it: TreeItem = get_next_selected(null)
	var removed: Array[SmokeSource] = []
	var removed_anims: Array[PropertyAnimation] = []
	var removed_items: Array[TreeItem] = []
	var indices: Array[int]
	while it != null:
		removed.append(sources[it])
		removed_anims.append_array(AnimationHandler.remove_object(sources[it]))
		removed_items.append(it)
		indices.append(removed[-1].get_index())
		it = get_next_selected(it)
	for item: TreeItem in removed_items:
		remove_source(item)
	selection.clear()
	source_settings.source = null
	update_ui.call_deferred()
	deselect_all()
	var removed_objs: Array[Object] = []
	removed_objs.assign(removed)
	EditHistory.submit_custom_actions([func () -> void:
		for src: SmokeSource in removed:
			remove_source_object(src)
			AnimationHandler.remove_object(src)
		], [func () -> void:
		for idx: int in removed.size():
			add_source(removed[idx], indices[idx])
		AnimationHandler.add_animations(removed_anims)]
		, update_ui, removed_objs, [])
