extends Window

@onready var rich_text_label: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
@onready var tab_bar: TabBar = $VBoxContainer/TabBar

var license_tabs: Array[String]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	close_requested.connect(hide)
	rich_text_label.meta_clicked.connect(on_url_clicked)
	
	tab_bar.add_tab("Components")
	tab_bar.tab_changed.connect(tab_selected)
	
	for key: String in Engine.get_license_info():
		license_tabs.append(key)
		tab_bar.add_tab(key)
	
	text_edit.text = construct_copyright_info()


func on_url_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))

func _on_ok_button_pressed() -> void:
	hide()

func construct_copyright_info() -> String:
	var comps: Array[Dictionary] = Engine.get_copyright_info()
	var txt: String = ""
	
	for comp: Dictionary in comps:
		txt += "- " + comp["name"] + "\n"
		for part: Dictionary in comp["parts"]:
			for cp: String in part["copyright"]:
				txt += "   © " + cp + "\n"
			txt += "   license: " + part["license"] + "\n\n"
	
	return txt

func tab_selected(tab: int) -> void:
	if tab == 0:
		text_edit.text = construct_copyright_info()
	else:
		text_edit.text = Engine.get_license_info()[license_tabs[tab - 1]]
