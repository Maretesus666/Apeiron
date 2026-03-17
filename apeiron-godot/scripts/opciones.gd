extends Control

const FONT            := preload("res://assets/fonts/ultrakill.ttf")
const FONT_SIZE_TITLE := 36
const FONT_SIZE_SEC   := 17
const FONT_SIZE_OPT   := 19
const FONT_SIZE_VAL   := 18
const FONT_SIZE_DESC  := 13

const COL_ON     := Color(0.2,  1.0,  0.35)
const COL_OFF    := Color(1.0,  0.3,  0.3)
const COL_ACCENT := Color(0.3,  0.75, 1.0)
const COL_DIM    := Color(0.55, 0.55, 0.55)

var _mobile_btn:    Button
var _fps_btn:       Button
var _shake_btn:     Button
var _master_slider: HSlider
var _music_slider:  HSlider
var _sfx_slider:    HSlider
var _bright_slider: HSlider
var _master_val:    Label
var _music_val:     Label
var _sfx_val:       Label
var _bright_val:    Label
var _brightness_overlay: ColorRect = null

signal closed

func _ready() -> void:
	_build()
	_apply_saved_brightness()

func _build() -> void:
	# Fondo oscuro
	var bg := ColorRect.new()
	bg.color        = Color(0, 0, 0, 0.82)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Panel que ocupa casi toda la pantalla con márgenes pequeños
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left   =  30
	panel.offset_top    =  20
	panel.offset_right  = -30
	panel.offset_bottom = -20
	add_child(panel)

	# VBox principal con padding, SIN scroll
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left   = 20
	outer.offset_top    = 10
	outer.offset_right  = -20
	outer.offset_bottom = -10
	outer.add_theme_constant_override("separation", 4)
	panel.add_child(outer)

	# Título
	var title := Label.new()
	title.text = "OPCIONES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	outer.add_child(title)

	outer.add_child(_sep())

	# ── AUDIO ─────────────────────────────────────────────────────────────────
	outer.add_child(_sec("— AUDIO —"))

	var mr := _slider_row("Vol. General", ConfigManager.master_volume)
	_master_slider = mr[0]; _master_val = mr[1]
	_master_slider.value_changed.connect(func(v): _pct_lbl(_master_val, v); ConfigManager.set_master_volume(v))
	outer.add_child(mr[2])

	var mus := _slider_row("Música", ConfigManager.music_volume)
	_music_slider = mus[0]; _music_val = mus[1]
	_music_slider.value_changed.connect(func(v): _pct_lbl(_music_val, v); ConfigManager.set_music_volume(v))
	outer.add_child(mus[2])

	var sfx := _slider_row("Efectos SFX", ConfigManager.sfx_volume)
	_sfx_slider = sfx[0]; _sfx_val = sfx[1]
	_sfx_slider.value_changed.connect(func(v): _pct_lbl(_sfx_val, v); ConfigManager.set_sfx_volume(v))
	outer.add_child(sfx[2])

	outer.add_child(_sep())

	# ── VISUAL ────────────────────────────────────────────────────────────────
	outer.add_child(_sec("— VISUAL —"))

	var br := _slider_row("Brillo", ConfigManager.brightness, 0.5, 1.5)
	_bright_slider = br[0]; _bright_val = br[1]
	_bright_slider.value_changed.connect(func(v): _pct_lbl(_bright_val, v, 0.5, 1.5); _on_brightness(v))
	outer.add_child(br[2])

	_fps_btn   = _make_toggle(ConfigManager.show_fps)
	_shake_btn = _make_toggle(ConfigManager.screenshake_enabled)
	_fps_btn.pressed.connect(_on_fps)
	_shake_btn.pressed.connect(_on_shake)
	outer.add_child(_toggle_row("Mostrar FPS",  "FPS en el HUD de juego.", _fps_btn))
	outer.add_child(_toggle_row("Screen Shake", "Vibración de cámara.", _shake_btn))

	outer.add_child(_sep())

	# ── CONTROLES ─────────────────────────────────────────────────────────────
	outer.add_child(_sec("— CONTROLES —"))

	_mobile_btn = _make_toggle(ConfigManager.mobile_controls_enabled)
	_mobile_btn.pressed.connect(_on_mobile)
	outer.add_child(_toggle_row("Controles Móviles", "Joystick táctil + botón FIRE.", _mobile_btn))

	# Espaciador flexible para empujar el botón abajo
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(spacer)

	outer.add_child(_sep())

	# Botón VOLVER — siempre visible al fondo
	var close_btn := Button.new()
	close_btn.text                  = "VOLVER"
	close_btn.custom_minimum_size   = Vector2(0, 50)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.add_theme_font_override("font", FONT)
	close_btn.add_theme_font_size_override("font_size", FONT_SIZE_OPT)
	close_btn.pressed.connect(_on_close)
	outer.add_child(close_btn)

# ─── Helpers ──────────────────────────────────────────────────────────────────
func _sec(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", FONT_SIZE_SEC)
	l.add_theme_color_override("font_color", COL_ACCENT)
	return l

func _sep() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_color_override("color", Color(1, 1, 1, 0.12))
	return s

func _slider_row(label_text: String, current: float,
		min_v: float = 0.0, max_v: float = 1.0) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 34)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(150, 0)
	lbl.add_theme_font_override("font", FONT)
	lbl.add_theme_font_size_override("font_size", FONT_SIZE_OPT)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value             = min_v
	slider.max_value             = max_v
	slider.step                  = 0.01
	slider.value                 = current
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size   = Vector2(0, 28)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size  = Vector2(50, 0)
	val_lbl.add_theme_font_override("font", FONT)
	val_lbl.add_theme_font_size_override("font_size", FONT_SIZE_VAL)
	val_lbl.add_theme_color_override("font_color", COL_ACCENT)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	val_lbl.text = _pct_str(current, min_v, max_v)
	row.add_child(val_lbl)

	return [slider, val_lbl, row]

func _pct_str(v: float, min_v: float = 0.0, max_v: float = 1.0) -> String:
	return "%d%%" % int((v - min_v) / (max_v - min_v) * 100.0)

func _pct_lbl(lbl: Label, v: float, min_v: float = 0.0, max_v: float = 1.0) -> void:
	lbl.text = _pct_str(v, min_v, max_v)

func _make_toggle(current: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(90, 36)
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", FONT_SIZE_OPT)
	_set_toggle(btn, current)
	return btn

func _set_toggle(btn: Button, on: bool) -> void:
	btn.text = "ON" if on else "OFF"
	btn.add_theme_color_override("font_color", COL_ON if on else COL_OFF)

func _toggle_row(label_text: String, desc_text: String, btn: Button) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 42)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_override("font", FONT)
	lbl.add_theme_font_size_override("font_size", FONT_SIZE_OPT)
	texts.add_child(lbl)

	var sub := Label.new()
	sub.text = desc_text
	sub.add_theme_font_override("font", FONT)
	sub.add_theme_font_size_override("font_size", FONT_SIZE_DESC)
	sub.add_theme_color_override("font_color", COL_DIM)
	texts.add_child(sub)

	row.add_child(texts)
	row.add_child(btn)
	return row

# ─── Brillo ───────────────────────────────────────────────────────────────────
func _apply_saved_brightness() -> void:
	_ensure_brightness_overlay()
	_update_brightness_overlay(ConfigManager.brightness)

func _ensure_brightness_overlay() -> void:
	if is_instance_valid(_brightness_overlay):
		return
	var existing = get_tree().root.find_child("BrightnessOverlay", true, false)
	if existing:
		_brightness_overlay = existing
		return
	var ol := ColorRect.new()
	ol.name         = "BrightnessOverlay"
	ol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ol.z_index      = 100
	ol.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(ol)
	_brightness_overlay = ol

func _update_brightness_overlay(v: float) -> void:
	_ensure_brightness_overlay()
	if not is_instance_valid(_brightness_overlay):
		return
	if v < 1.0:
		_brightness_overlay.color = Color(0, 0, 0, 1.0 - v)
	else:
		_brightness_overlay.color = Color(1, 1, 1, (v - 1.0) * 0.7)

func _on_brightness(v: float) -> void:
	ConfigManager.set_brightness(v)
	_update_brightness_overlay(v)

# ─── Callbacks ────────────────────────────────────────────────────────────────
func _on_fps() -> void:
	var new_val := not ConfigManager.show_fps
	ConfigManager.set_show_fps(new_val)
	_set_toggle(_fps_btn, new_val)
	# El HUD se actualiza solo porque lee ConfigManager.show_fps en _build_fps_label

func _on_shake() -> void:
	var new_val := not ConfigManager.screenshake_enabled
	ConfigManager.set_screenshake(new_val)
	_set_toggle(_shake_btn, new_val)

func _on_mobile() -> void:
	var new_val := not ConfigManager.mobile_controls_enabled
	ConfigManager.set_mobile_controls(new_val)
	_set_toggle(_mobile_btn, new_val)

func _on_close() -> void:
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close()
