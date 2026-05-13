extends Node

# ─── Estado ───────────────────────────────────────────────────────────────────
var mobile_controls_enabled: bool  = false
var master_volume:           float = 1.0
var music_volume:            float = 0.8
var sfx_volume:              float = 1.0
var brightness:              float = 1.0
var show_fps:                bool  = false
var screenshake_enabled:     bool  = true

signal mobile_controls_changed(enabled: bool)

const SAVE_PATH := "user://config.save"

func _ready() -> void:
	# Detectar plataforma móvil automáticamente
	var os_name := OS.get_name()
	if os_name == "Android" or os_name == "iOS":
		mobile_controls_enabled = true
	_load()
	_apply_all()

# ─── Setters ──────────────────────────────────────────────────────────────────
func set_mobile_controls(value: bool) -> void:
	mobile_controls_enabled = value
	mobile_controls_changed.emit(value)
	_save()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_bus("Master", master_volume)
	_save()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus("Music", music_volume)
	_save()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus("SFX", sfx_volume)
	_save()

func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.5, 1.5)
	_save()

func set_show_fps(value: bool) -> void:
	show_fps = value
	_save()

func set_screenshake(value: bool) -> void:
	screenshake_enabled = value
	_save()

# ─── Aplicar al AudioServer ───────────────────────────────────────────────────
func _apply_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if linear <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

func _apply_all() -> void:
	_apply_bus("Master", master_volume)
	_apply_bus("Music",  music_volume)
	_apply_bus("SFX",    sfx_volume)

# ─── Persistencia ─────────────────────────────────────────────────────────────
func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_var({
		"mobile_controls": mobile_controls_enabled,
		"master_volume":   master_volume,
		"music_volume":    music_volume,
		"sfx_volume":      sfx_volume,
		"brightness":      brightness,
		"show_fps":        show_fps,
		"screenshake":     screenshake_enabled,
	})
	file.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var data: Variant = file.get_var()
	file.close()
	if not data is Dictionary:
		return
	mobile_controls_enabled = data.get("mobile_controls", false)
	master_volume           = data.get("master_volume",   1.0)
	music_volume            = data.get("music_volume",    0.8)
	sfx_volume              = data.get("sfx_volume",      1.0)
	brightness              = data.get("brightness",      1.0)
	show_fps                = data.get("show_fps",        false)
	screenshake_enabled     = data.get("screenshake",     true)
