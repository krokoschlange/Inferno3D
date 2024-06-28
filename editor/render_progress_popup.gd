class_name RenderProgressPopup
extends Control

@onready var label: Label = $PanelContainer/MarginContainer/VBoxContainer/Label
@onready var progress_bar: ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/ProgressBar
@onready var container: MarginContainer = $PanelContainer/MarginContainer


func start(frames: int) -> void:
	label.text = "Rendering Frame %d/%d" % [1, frames]
	progress_bar.value = 0
	progress_bar.max_value = frames
	show()
	container.hide()
	container.show.call_deferred()

func frame() -> void:
	progress_bar.value += 1
	label.text = "Rendering Frame %d/%d" % [progress_bar.value + 1, progress_bar.max_value]

func end() -> void:
	hide()
