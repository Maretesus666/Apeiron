extends Control

@onready var panel: Panel = null
@onready var overlay: TextureRect = null

const PANEL_WIDTH := 900.0  # Panel más ancho para mejor lectura
const FONT := preload("res://assets/fonts/ultrakill.ttf")

var _tween: Tween
var _tipo_actual := ""
var title_lbl: Label
var puntos_lbl: Label
var upgrades_container: VBoxContainer

func _ready() -> void:
	# Obtener referencias a los nodos hijos
	panel = get_node_or_null("Panel")
	overlay = get_node_or_null("Overlay")
	
	if not panel or not overlay:
		push_error("Panel o Overlay no encontrado")
		return
	
	_build_ui()
	
	if overlay:
		overlay.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed: 
				cerrar()
		)
	
	# Posicionar el panel fuera de la pantalla (derecha)
	panel.position.x = get_viewport_rect().size.x
	visible = false

func _build_ui() -> void:
	if not panel:
		return
	
	# Ajustar el tamaño del panel
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.size = Vector2(PANEL_WIDTH, get_viewport_rect().size.y)
	
	# Estilo del panel principal con gradiente
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	style.border_width_left = 4
	style.border_color = Color(0.25, 0.55, 1.0, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_bottom_left = 12
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	
	# Overlay oscuro
	if overlay:
		overlay.modulate = Color(0, 0, 0, 0.75)
	
	# Limpiar panel antes de construir
	for child in panel.get_children():
		child.queue_free()
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.anchor_left = 0.0
	margin.anchor_top = 0.0
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)
	
	# Header
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	
	# Botón cerrar con mejor diseño
	var close_btn := Button.new()
	close_btn.text = "✕ CERRAR"
	close_btn.custom_minimum_size = Vector2(0, 50)
	close_btn.add_theme_font_override("font", FONT)
	close_btn.add_theme_font_size_override("font_size", 26)
	close_btn.add_theme_color_override("font_color", Color(1, 0.35, 0.35))
	close_btn.pressed.connect(cerrar)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.25, 0.05, 0.05, 0.6)
	close_style.corner_radius_top_left = 8
	close_style.corner_radius_top_right = 8
	close_style.corner_radius_bottom_left = 8
	close_style.corner_radius_bottom_right = 8
	close_style.border_width_left = 2
	close_style.border_width_top = 2
	close_style.border_width_right = 2
	close_style.border_width_bottom = 2
	close_style.border_color = Color(1, 0.2, 0.2, 0.4)
	close_btn.add_theme_stylebox_override("normal", close_style)
	
	var close_hover := StyleBoxFlat.new()
	close_hover.bg_color = Color(0.35, 0.08, 0.08, 0.8)
	close_hover.corner_radius_top_left = 8
	close_hover.corner_radius_top_right = 8
	close_hover.corner_radius_bottom_left = 8
	close_hover.corner_radius_bottom_right = 8
	close_hover.border_width_left = 2
	close_hover.border_width_top = 2
	close_hover.border_width_right = 2
	close_hover.border_width_bottom = 2
	close_hover.border_color = Color(1, 0.3, 0.3, 0.6)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	header.add_child(close_btn)
	
	# Título con efecto de brillo
	title_lbl = Label.new()
	title_lbl.add_theme_font_override("font", FONT)
	title_lbl.add_theme_font_size_override("font_size", 44)
	title_lbl.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.3, 0.5, 0.8))
	title_lbl.add_theme_constant_override("outline_size", 2)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title_lbl)
	
	# Puntos con diseño mejorado
	var puntos_panel := PanelContainer.new()
	var puntos_style := StyleBoxFlat.new()
	puntos_style.bg_color = Color(0.15, 0.12, 0.05, 0.6)
	puntos_style.corner_radius_top_left = 10
	puntos_style.corner_radius_top_right = 10
	puntos_style.corner_radius_bottom_left = 10
	puntos_style.corner_radius_bottom_right = 10
	puntos_style.border_width_left = 2
	puntos_style.border_width_top = 2
	puntos_style.border_width_right = 2
	puntos_style.border_width_bottom = 2
	puntos_style.border_color = Color(1, 0.85, 0.2, 0.5)
	puntos_panel.add_theme_stylebox_override("panel", puntos_style)
	
	var puntos_margin := MarginContainer.new()
	puntos_margin.add_theme_constant_override("margin_left", 20)
	puntos_margin.add_theme_constant_override("margin_right", 20)
	puntos_margin.add_theme_constant_override("margin_top", 12)
	puntos_margin.add_theme_constant_override("margin_bottom", 12)
	puntos_panel.add_child(puntos_margin)
	
	puntos_lbl = Label.new()
	puntos_lbl.add_theme_font_override("font", FONT)
	puntos_lbl.add_theme_font_size_override("font_size", 30)
	puntos_lbl.add_theme_color_override("font_color", Color(1, 0.95, 0.3))
	puntos_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	puntos_lbl.add_theme_constant_override("outline_size", 2)
	puntos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	puntos_margin.add_child(puntos_lbl)
	header.add_child(puntos_panel)
	
	# Separador decorativo
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.35, 0.45, 0.6, 0.4)
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)
	
	# Scroll container con mejor estilo
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
	var target_x = get_viewport_rect().size.x - PANEL_WIDTH
	_animar(target_x)

func cerrar() -> void:
	var target_x = get_viewport_rect().size.x
	_animar(target_x, true)

func _animar(destino_x: float, ocultar_al_terminar := false) -> void:
	if not panel:
		return
	
	if _tween and is_instance_valid(_tween): 
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_IN if ocultar_al_terminar else Tween.EASE_OUT)
	_tween.tween_property(panel, "position:x", destino_x, 0.4)
	
	if ocultar_al_terminar:
		_tween.tween_callback(func(): visible = false)

func _poblar() -> void:
	if not upgrades_container or not title_lbl or not puntos_lbl:
		return
	
	# Limpiar
	for c in upgrades_container.get_children():
		c.queue_free()

	if _tipo_actual == "nucleo":
		title_lbl.text = "⚡ MEJORAS DEL NÚCLEO"
		puntos_lbl.text = "💰 Puntos de Juego: %s" % _format_number(UpgradeManager.game_points)
		
		# Descripción del sistema
		var desc := Label.new()
		desc.text = "Mejora tu generación de puntos clicker"
		desc.add_theme_font_override("font", FONT)
		desc.add_theme_font_size_override("font_size", 16)
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		upgrades_container.add_child(desc)
		
		_agregar_categoria("⚡ PRODUCCIÓN", 
			["points_per_click", "click_multiplier", "bulk_clicks"], 
			"clicker",
			"Aumenta los puntos que generas por click")
		
		_agregar_categoria("🤖 AUTOMATIZACIÓN", 
			["auto_clicker_speed", "passive_income"], 
			"clicker",
			"Genera puntos automáticamente")
		
		_agregar_categoria("✨ BONIFICACIONES", 
			["critical_chance", "critical_multiplier", "combo_bonus"], 
			"clicker",
			"Multiplica tus ganancias con efectos especiales")
	else:
		title_lbl.text = "🚀 MEJORAS DE LA NAVE"
		puntos_lbl.text = "💰 Puntos Clicker: %s" % _format_number(UpgradeManager.clicker_points)
		
		# Descripción del sistema
		var desc := Label.new()
		desc.text = "Mejora las estadísticas de tu nave para el combate"
		desc.add_theme_font_override("font", FONT)
		desc.add_theme_font_size_override("font_size", 16)
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		upgrades_container.add_child(desc)
		
		_agregar_categoria("🏃 MOVILIDAD", 
			["max_speed", "acceleration", "thrust_power", "rotation_speed"], 
			"ship",
			"Mejora velocidad y maniobrabilidad")
		
		_agregar_categoria("⚔️ COMBATE", 
			["fire_rate", "bullet_speed", "bullet_damage"], 
			"ship",
			"Aumenta tu poder de fuego")
		
		_agregar_categoria("🛡️ DEFENSA", 
			["max_health", "lateral_agility"], 
			"ship",
			"Mejora supervivencia y evasión")

	# Conectar señales para actualizar
	if not UpgradeManager.clicker_points_changed.is_connected(_on_puntos):
		UpgradeManager.clicker_points_changed.connect(_on_puntos)
	if not UpgradeManager.game_points_changed.is_connected(_on_puntos):
		UpgradeManager.game_points_changed.connect(_on_puntos)

func _format_number(num: int) -> String:
	if num >= 1_000_000_000:
		return "%.2fB" % (num / 1_000_000_000.0)
	elif num >= 1_000_000:
		return "%.2fM" % (num / 1_000_000.0)
	elif num >= 1_000:
		return "%.1fK" % (num / 1_000.0)
	else:
		return "%d" % num

func _agregar_categoria(nombre: String, upgrade_ids: Array, tipo: String, descripcion: String = "") -> void:
	if not upgrades_container:
		return
	
	# Panel de categoría con diseño mejorado
	var cat_panel := PanelContainer.new()
	var cat_style := StyleBoxFlat.new()
	cat_style.bg_color = Color(0.12, 0.15, 0.22, 0.5)
	cat_style.corner_radius_top_left = 8
	cat_style.corner_radius_top_right = 8
	cat_style.corner_radius_bottom_left = 8
	cat_style.corner_radius_bottom_right = 8
	cat_panel.add_theme_stylebox_override("panel", cat_style)
	
	var cat_margin := MarginContainer.new()
	cat_margin.add_theme_constant_override("margin_left", 15)
	cat_margin.add_theme_constant_override("margin_right", 15)
	cat_margin.add_theme_constant_override("margin_top", 10)
	cat_margin.add_theme_constant_override("margin_bottom", 10)
	cat_panel.add_child(cat_margin)
	
	var cat_vbox := VBoxContainer.new()
	cat_vbox.add_theme_constant_override("separation", 4)
	cat_margin.add_child(cat_vbox)
	
	# Título de categoría
	var cat_label := Label.new()
	cat_label.text = nombre
	cat_label.add_theme_font_override("font", FONT)
	cat_label.add_theme_font_size_override("font_size", 24)
	cat_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	cat_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	cat_label.add_theme_constant_override("outline_size", 1)
	cat_vbox.add_child(cat_label)
	
	# Descripción de categoría
	if descripcion != "":
		var cat_desc := Label.new()
		cat_desc.text = descripcion
		cat_desc.add_theme_font_override("font", FONT)
		cat_desc.add_theme_font_size_override("font_size", 14)
		cat_desc.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 0.9))
		cat_vbox.add_child(cat_desc)
	
	upgrades_container.add_child(cat_panel)
	
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
	
	# VERIFICACIÓN DE SEGURIDAD
	if not id in upgrades:
		push_error("Mejora '%s' no encontrada en %s_upgrades" % [id, tipo])
		var error_panel := PanelContainer.new()
		var error_label := Label.new()
		error_label.text = "⚠️ Error: mejora '%s' no encontrada" % id
		error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		error_panel.add_child(error_label)
		return error_panel
	
	var upgrade_data = upgrades[id]
	var cost := UpgradeManager.get_clicker_upgrade_cost(id) if tipo == "clicker" else UpgradeManager.get_ship_upgrade_cost(id)
	var pts  := UpgradeManager.game_points if tipo == "clicker" else UpgradeManager.clicker_points
	var can_afford := pts >= cost
	
	# Panel container
	var panel_container := PanelContainer.new()
	panel_container.custom_minimum_size = Vector2(0, 95)
	var style := StyleBoxFlat.new()
	
	if can_afford:
		style.bg_color = Color(0.08, 0.22, 0.32, 0.75)
		style.border_color = Color(0.35, 0.65, 1.0, 0.7)
	else:
		style.bg_color = Color(0.12, 0.12, 0.12, 0.55)
		style.border_color = Color(0.25, 0.25, 0.25, 0.5)
	
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel_container.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel_container.add_child(margin)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	margin.add_child(hbox)
	
	# Info de la mejora
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(info_vbox)
	
	# Nombre
	var name_label := Label.new()
	var nombre: String = upgrade_data.get("desc", id.replace("_", " ").capitalize())
	name_label.text = nombre
	name_label.add_theme_font_override("font", FONT)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color.WHITE if can_afford else Color(0.5, 0.5, 0.5))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	name_label.add_theme_constant_override("outline_size", 1)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(name_label)
	
	# Stats detallados
	var current_value: float = float(upgrade_data["level"]) * float(upgrade_data["value"])
	var next_value: float = float(upgrade_data["level"] + 1) * float(upgrade_data["value"])
	var stats_text := "Nivel %d  •  Total: +%s  →  +%s" % [
		upgrade_data["level"], 
		_format_stat(current_value),
		_format_stat(next_value)
	]
	
	var stats_label := Label.new()
	stats_label.text = stats_text
	stats_label.add_theme_font_override("font", FONT)
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95) if can_afford else Color(0.4, 0.4, 0.45))
	info_vbox.add_child(stats_label)
	
	# Costo con diseño mejorado
	var cost_vbox := VBoxContainer.new()
	cost_vbox.add_theme_constant_override("separation", 2)
	cost_vbox.custom_minimum_size = Vector2(160, 0)
	hbox.add_child(cost_vbox)
	
	var cost_label := Label.new()
	cost_label.text = _format_number(cost)
	cost_label.add_theme_font_override("font", FONT)
	cost_label.add_theme_font_size_override("font_size", 32)
	cost_label.add_theme_color_override("font_color", Color(1, 0.95, 0.35) if can_afford else Color(1, 0.35, 0.35))
	cost_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	cost_label.add_theme_constant_override("outline_size", 2)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_vbox.add_child(cost_label)
	
	var pts_label := Label.new()
	pts_label.text = "puntos"
	pts_label.add_theme_font_override("font", FONT)
	pts_label.add_theme_font_size_override("font_size", 14)
	pts_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	pts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_vbox.add_child(pts_label)
	
	# Indicador de disponibilidad
	if can_afford:
		var buy_hint := Label.new()
		buy_hint.text = "► CLICK PARA COMPRAR"
		buy_hint.add_theme_font_override("font", FONT)
		buy_hint.add_theme_font_size_override("font_size", 13)
		buy_hint.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 0.7))
		buy_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cost_vbox.add_child(buy_hint)
	
	# Botón invisible para capturar clicks
	var btn := Button.new()
	btn.disabled = not can_afford
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func():
		var ok := UpgradeManager.buy_clicker_upgrade(id) if tipo == "clicker" else UpgradeManager.buy_ship_upgrade(id)
		if ok: 
			_poblar()
			# Efecto visual de compra
			_flash_purchase()
	)
	
	# Estilo transparente para el botón
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	
	btn.anchor_left = 0.0
	btn.anchor_top = 0.0
	btn.anchor_right = 1.0
	btn.anchor_bottom = 1.0
	margin.add_child(btn)
	
	return panel_container

func _format_stat(value: float) -> String:
	if value >= 1000:
		return "%.1fK" % (value / 1000.0)
	elif value >= 1:
		return "%.1f" % value
	else:
		return "%.2f" % value

func _flash_purchase() -> void:
	# Pequeño flash visual cuando compras algo
	if not panel:
		return
	var flash := ColorRect.new()
	flash.color = Color(0.3, 0.7, 1.0, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(flash)
	
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.3)
	tw.tween_callback(flash.queue_free)
