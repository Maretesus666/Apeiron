extends Node

# ─── Ajustes ──────────────────────────────────────────────────────────────────
var mobile_controls_enabled: bool = false

signal mobile_controls_changed(enabled: bool)

const SAVE_PATH := "user://config.save"

func _ready() -> void:
	_load()

func set_mobile_controls(value: bool) -> void:
	mobile_controls_enabled = value
	mobile_controls_changed.emit(value)
	_save()

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var({ "mobile_controls": mobile_controls_enabled })
		file.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data: Variant = file.get_var()
		file.close()
		if data is Dictionary:
			mobile_controls_enabled = data.get("mobile_controls", false)
