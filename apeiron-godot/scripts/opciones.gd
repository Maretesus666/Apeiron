extends Control

# Panel de opciones que se superpone al menú principal.
# Se instancia por código desde menu.gd.

const FONT      := preload("res://assets/fonts/ultrakill.ttf")
const FONT_SIZE_TITLE := 52
const FONT_SIZE_OPT   := 36
const FONT_SIZE_DESC  := 22

var _panel:        Panel
var _mobile_btn:   Button

signal closed

func _ready() -> void:
	_build()
	_refresh_button()

func _build() -> void:
	# Fondo oscuro semitransparente que cubre toda la pantalla
	var overlay := ColorRect.new()
	overlay.color            = Color(0, 0, 0, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Panel centrado
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(520, 380)
	_panel.offset_left   = -260
	_panel.offset_top    = -190
	_panel.offset_right  =  260
	_panel.offset_bottom =  190
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   = 32
	vbox.offset_top    = 28
	vbox.offset_right  = -32
	vbox.offset_bottom = -28
	_panel.add_child(vbox)

	# Título
	var title := Label.new()
	title.text = "OPCIONES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	vbox.add_child(title)

	# Separador
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# ── Opción: controles móviles ─────────────────────────────────────────────
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	vbox.add_child(row)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(desc_vbox)

	var opt_label := Label.new()
	opt_label.text = "Controles Móviles"
	opt_label.add_theme_font_override("font", FONT)
	opt_label.add_theme_font_size_override("font_size", FONT_SIZE_OPT)
	desc_vbox.add_child(opt_label)

	var sub_label := Label.new()
	sub_label.text = "Joystick + botón FIRE. Desactiva el cursor."
	sub_label.add_theme_font_override("font", FONT)
	sub_label.add_theme_font_size_override("font_size", FONT_SIZE_DESC)
	sub_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_vbox.add_child(sub_label)

	_mobile_btn = Button.new()
	_mobile_btn.add_theme_font_override("font", FONT)
	_mobile_btn.add_theme_font_size_override("font_size", FONT_SIZE_OPT)
	_mobile_btn.custom_minimum_size = Vector2(140, 0)
	_mobile_btn.pressed.connect(_on_mobile_toggle)
	row.add_child(_mobile_btn)

	# Espaciador
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Botón cerrar
	var close_btn := Button.new()
	close_btn.text = "VOLVER" 
	close_btn.add_theme_font_override("font", FONT)
	close_btn.add_theme_font_size_override("font_size", FONT_SIZE_OPT)
	close_btn.pressed.connect(_on_close)
	vbox.add_child(close_btn)

func _refresh_button() -> void:
	if not _mobile_btn:
		return
	var on: bool = ConfigManager.mobile_controls_enabled
	_mobile_btn.text = "ON" if on else "OFF"
	_mobile_btn.add_theme_color_override(
		"font_color",
		Color(0.2, 1.0, 0.35) if on else Color(1.0, 0.3, 0.3)
	)

func _on_mobile_toggle() -> void:
	ConfigManager.set_mobile_controls(not ConfigManager.mobile_controls_enabled)
	_refresh_button()

func _on_close() -> void:
	closed.emit()
	queue_free()

# Cerrar también con Escape
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close()
