extends Control

@onready var panel       := $Panel
@onready var overlay     := $Overlay

const PANEL_X_ABIERTO := 0.0
const PANEL_X_CERRADO := 1080.0
const FONT := preload("res://assets/fonts/ultrakill.ttf")

var _tween: Tween
var _tipo_actual := ""
var title_lbl: Label
var puntos_lbl: Label
var upgrades_container: VBoxContainer

func _ready() -> void:
	_build_ui()
	overlay.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: cerrar()
	)
	panel.position.x = PANEL_X_CERRADO
	visible = false

func _build_ui() -> void:
	# Estilo del panel principal
	if panel:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
		style.border_width_left = 3
		style.border_color = Color(0.2, 0.5, 1.0, 0.8)
		style.corner_radius_top_left = 8
		style.corner_radius_bottom_left = 8
		panel.add_theme_stylebox_override("panel", style)
	
	# Overlay oscuro
	if overlay:
		overlay.color = Color(0, 0, 0, 0.7)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Header
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	
	# Botón cerrar
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.add_theme_font_override("font", FONT)
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	close_btn.pressed.connect(cerrar)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.2, 0.05, 0.05, 0.5)
	close_style.corner_radius_top_left = 4
	close_style.corner_radius_top_right = 4
	close_style.corner_radius_bottom_left = 4
	close_style.corner_radius_bottom_right = 4
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_style)
	header.add_child(close_btn)
	
	# Título
	title_lbl = Label.new()
	title_lbl.add_theme_font_override("font", FONT)
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title_lbl)
	
	# Puntos
	puntos_lbl = Label.new()
	puntos_lbl.add_theme_font_override("font", FONT)
	puntos_lbl.add_theme_font_size_override("font_size", 28)
	puntos_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	puntos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(puntos_lbl)
	
	# Separador
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.3, 0.3, 0.4, 0.5)
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)
	
	# Scroll container
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	# Contenedor de upgrades
	upgrades_container = VBoxContainer.new()
	upgrades_container.add_theme_constant_override("separation", 12)
	scroll.add_child(upgrades_container)

func abrir(tipo: String) -> void:
	_tipo_actual = tipo
	visible = true
	_poblar()
	_animar(PANEL_X_ABIERTO)

func cerrar() -> void:
	_animar(PANEL_X_CERRADO, true)

func _animar(destino_x: float, ocultar_al_terminar := false) -> void:
	if _tween: _tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(
		Tween.EASE_IN if ocultar_al_terminar else Tween.EASE_OUT
	)
	_tween.tween_property(panel, "position:x", destino_x, 0.35)
	if ocultar_al_terminar:
		_tween.tween_callback(func(): visible = false)

func _poblar() -> void:
	# Limpiar
	for c in upgrades_container.get_children():
		c.queue_free()

	if _tipo_actual == "nucleo":
		title_lbl.text = "⚡ MEJORAS NÚCLEO"
		puntos_lbl.text = "💰 Puntos de juego: %d" % UpgradeManager.game_points
		_agregar_categoria("Producción", ["points_per_click", "click_multiplier", "bulk_clicks"], "clicker")
		_agregar_categoria("Automatización", ["auto_clicker_speed", "passive_income"], "clicker")
		_agregar_categoria("Bonificaciones", ["critical_chance", "critical_multiplier", "combo_bonus"], "clicker")
	else:
		title_lbl.text = "🚀 MEJORAS NAVE"
		puntos_lbl.text = "💰 Puntos clicker: %d" % UpgradeManager.clicker_points
		_agregar_categoria("Movilidad", ["max_speed", "acceleration", "thrust_power", "rotation_speed"], "ship")
		_agregar_categoria("Combate", ["fire_rate", "bullet_speed", "bullet_damage"], "ship")
		_agregar_categoria("Defensa", ["max_health", "lateral_agility"], "ship")

	# Conectar señales para actualizar
	if not UpgradeManager.clicker_points_changed.is_connected(_on_puntos):
		UpgradeManager.clicker_points_changed.connect(_on_puntos)
	if not UpgradeManager.game_points_changed.is_connected(_on_puntos):
		UpgradeManager.game_points_changed.connect(_on_puntos)

func _agregar_categoria(nombre: String, upgrade_ids: Array, tipo: String) -> void:
	# Título de categoría
	var cat_label := Label.new()
	cat_label.text = "▶ " + nombre.to_upper()
	cat_label.add_theme_font_override("font", FONT)
	cat_label.add_theme_font_size_override("font_size", 24)
	cat_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	upgrades_container.add_child(cat_label)
	
	# Mejoras de la categoría
	for id in upgrade_ids:
		upgrades_container.add_child(_crear_boton(id, tipo))
	
	# Espaciador entre categorías
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	upgrades_container.add_child(spacer)

func _on_puntos(_v) -> void:
	if visible:
		_poblar()

func _crear_boton(id: String, tipo: String) -> PanelContainer:
	var upgrades: Dictionary = UpgradeManager.clicker_upgrades if tipo == "clicker" else UpgradeManager.ship_upgrades
	var upgrade_data = upgrades[id]
	var cost := UpgradeManager.get_clicker_upgrade_cost(id) if tipo == "clicker" else UpgradeManager.get_ship_upgrade_cost(id)
	var pts  := UpgradeManager.game_points if tipo == "clicker" else UpgradeManager.clicker_points
	var can_afford := pts >= cost
	
	# Panel container para el botón
	var panel_container := PanelContainer.new()
	var style := StyleBoxFlat.new()
	
	if can_afford:
		style.bg_color = Color(0.1, 0.2, 0.3, 0.6)
		style.border_color = Color(0.3, 0.6, 1.0, 0.5)
	else:
		style.bg_color = Color(0.15, 0.15, 0.15, 0.4)
		style.border_color = Color(0.3, 0.3, 0.3, 0.3)
	
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel_container.add_theme_stylebox_override("panel", style)
	
	# Botón invisible para capturar clicks
	var btn := Button.new()
	btn.disabled = not can_afford
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func():
		var ok := UpgradeManager.buy_clicker_upgrade(id) if tipo == "clicker" else UpgradeManager.buy_ship_upgrade(id)
		if ok: _poblar()
	)
	
	# Estilo transparente para el botón
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel_container.add_child(margin)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)
	
	# Info de la mejora
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)
	
	# Nombre
	var name_label := Label.new()
	var nombre := upgrade_data.get("desc", id.replace("_", " ").capitalize())
	name_label.text = nombre
	name_label.add_theme_font_override("font", FONT)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color.WHITE if can_afford else Color(0.5, 0.5, 0.5))
	info_vbox.add_child(name_label)
	
	# Stats
	var stats_label := Label.new()
	stats_label.text = "Nivel %d  •  +%s por nivel" % [upgrade_data["level"], str(upgrade_data["value"])]
	stats_label.add_theme_font_override("font", FONT)
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8) if can_afford else Color(0.4, 0.4, 0.4))
	info_vbox.add_child(stats_label)
	
	# Costo
	var cost_vbox := VBoxContainer.new()
	cost_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(cost_vbox)
	
	var cost_label := Label.new()
	cost_label.text = str(cost)
	cost_label.add_theme_font_override("font", FONT)
	cost_label.add_theme_font_size_override("font_size", 28)
	cost_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2) if can_afford else Color(1, 0.3, 0.3))
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_vbox.add_child(cost_label)
	
	var pts_label := Label.new()
	pts_label.text = "puntos"
	pts_label.add_theme_font_override("font", FONT)
	pts_label.add_theme_font_size_override("font_size", 14)
	pts_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	pts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_vbox.add_child(pts_label)
	
	margin.add_child(btn)
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	return panel_container
