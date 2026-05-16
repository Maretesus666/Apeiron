extends Control

@onready var scroller: ScrollContainer = $ContenedorBotones/ScrollContainer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var panel_mejoras := $PanelMejoras

var is_scrolling: bool = false
var page_width: float = 0.0
var scroll_pos: float = 0.0
var was_scrolling: bool = false
var button_tween: Tween = null

const FONT := preload("res://assets/fonts/ultrakill.ttf")
const OpcionesScene := preload("res://scripts/opciones.gd")

# Panel de apuesta
var bet_panel: Control = null
var bet_slider: HSlider = null
var bet_label: Label = null
var bet_reward_label: Label = null

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	page_width = scroller.get_child(0).get_child(0).size.x
	scroller.scroll_horizontal = 0  
	var nucleo := $ContenedorBotones/ScrollContainer/HBoxContainer/nucleo
	if nucleo.has_signal("mejoras_solicitadas"):
		nucleo.mejoras_solicitadas.connect(panel_mejoras.abrir)
	
	_mejorar_info_label()
	_mejorar_espaciado_nave()
	_mejorar_botones_nave()
	_actualizar_stats_nave()
	_actualizar_stats_nucleo()
	
	UpgradeManager.upgrade_purchased.connect(func(_t,_i): 
		_actualizar_stats_nave()
		_actualizar_stats_nucleo()
	)
	
	_build_bet_panel()
	_build_hamburger_menu()

func _build_hamburger_menu() -> void:
	# Botón hamburguesa en la esquina superior derecha
	var menu_btn := Button.new()
	menu_btn.text = "☰"
	menu_btn.custom_minimum_size = Vector2(60, 30)
	menu_btn.add_theme_font_override("font", FONT)
	menu_btn.add_theme_font_size_override("font_size", 40)
	menu_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	
	# Posición en esquina superior derecha
	menu_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_btn.position = Vector2(-1920, 10)
	
	# Estilo
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.4, 0.8)
	menu_btn.add_theme_stylebox_override("normal", style)
	
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8
	style_hover.border_width_left = 2
	style_hover.border_width_top = 2
	style_hover.border_width_right = 2
	style_hover.border_width_bottom = 2
	style_hover.border_color = Color(0.6, 0.6, 0.6, 1.0)
	menu_btn.add_theme_stylebox_override("hover", style_hover)
	
	menu_btn.pressed.connect(_on_menu_button_pressed)
	add_child(menu_btn)

func _on_menu_button_pressed() -> void:
	# Abrir menú de opciones
	var opciones := Control.new()
	opciones.set_script(OpcionesScene)
	opciones.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(opciones)
	opciones.closed.connect(func(): pass)

func _mejorar_info_label() -> void:
	var info_label: Label = $ContenedorBotones/ScrollContainer/HBoxContainer/Nave/VBoxContainer/InfoLabel
	if info_label:
		info_label.text = "◈  NAVE  ◈"
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_label.add_theme_font_override("font", FONT)
		info_label.add_theme_font_size_override("font_size", 38)
		info_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		info_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		info_label.add_theme_constant_override("outline_size", 3)

func _mejorar_espaciado_nave() -> void:
	var vbox: VBoxContainer = $ContenedorBotones/ScrollContainer/HBoxContainer/Nave/VBoxContainer
	if vbox:
		vbox.add_theme_constant_override("separation", 0)

func _mejorar_botones_nave() -> void:
	var play_btn: Button = $ContenedorBotones/ScrollContainer/HBoxContainer/Nave/VBoxContainer/PlayButton
	var mejoras_btn: Button = $ContenedorBotones/ScrollContainer/HBoxContainer/Nave/VBoxContainer/MejorasNaveBtn
	
	if play_btn:
		_aplicar_estilo_boton(play_btn, "JUGAR")
	
	if mejoras_btn:
		_aplicar_estilo_boton(mejoras_btn, "MEJORAS")

func _aplicar_estilo_boton(btn: Button, tipo: String) -> void:
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 52)
	
	var bg_normal := Color(0.12, 0.12, 0.12, 0.95)
	var bg_hover := Color(0.22, 0.22, 0.22, 0.98)
	var bg_pressed := Color(0.08, 0.08, 0.08, 1.0)
	var border_normal := Color(0.45, 0.45, 0.45, 0.8)
	var border_hover := Color(0.85, 0.85, 0.85, 0.95)
	var border_pressed := Color(0.25, 0.25, 0.25, 0.9)
	
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = bg_normal
	style_normal.border_width_left = 3
	style_normal.border_width_top = 3
	style_normal.border_width_right = 3
	style_normal.border_width_bottom = 3
	style_normal.border_color = border_normal
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	style_normal.content_margin_left = 30
	style_normal.content_margin_right = 30
	style_normal.content_margin_top = 20
	style_normal.content_margin_bottom = 20
	btn.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = bg_hover
	style_hover.border_width_left = 3
	style_hover.border_width_top = 3
	style_hover.border_width_right = 3
	style_hover.border_width_bottom = 3
	style_hover.border_color = border_hover
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6
	style_hover.content_margin_left = 30
	style_hover.content_margin_right = 30
	style_hover.content_margin_top = 20
	style_hover.content_margin_bottom = 20
	btn.add_theme_stylebox_override("hover", style_hover)
	
	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = bg_pressed
	style_pressed.border_width_left = 3
	style_pressed.border_width_top = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = border_pressed
	style_pressed.corner_radius_top_left = 6
	style_pressed.corner_radius_top_right = 6
	style_pressed.corner_radius_bottom_left = 6
	style_pressed.corner_radius_bottom_right = 6
	style_pressed.content_margin_left = 32
	style_pressed.content_margin_right = 28
	style_pressed.content_margin_top = 22
	style_pressed.content_margin_bottom = 18
	btn.add_theme_stylebox_override("pressed", style_pressed)
	
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.85, 0.85, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	btn.add_theme_constant_override("outline_size", 4)
	btn.custom_minimum_size = Vector2(0, 90)

func _actualizar_stats_nave() -> void:
	var container: VBoxContainer = $ContenedorBotones/ScrollContainer/HBoxContainer/Nave/VBoxContainer
	
	var stats_container = container.get_node_or_null("StatsContainer")
	if stats_container:
		container.remove_child(stats_container)
		stats_container.queue_free()
	
	var stats_dict = _crear_stats_container()
	var stats_panel = stats_dict["panel"]
	var stats_vbox = stats_dict["vbox"]
	stats_panel.name = "StatsContainer"
	
	var info_label = container.get_node_or_null("InfoLabel")
	if info_label:
		container.add_child(stats_panel)
		container.move_child(stats_panel, info_label.get_index() + 1)
	else:
		container.add_child(stats_panel)
	
	var stats = {
		"Velocidad": {"base": 6000, "bonus": int(UpgradeManager.get_ship_stat("max_speed"))},
		"Vida": {"base": 5, "bonus": int(UpgradeManager.get_ship_stat("max_health"))},
		"Daño": {"base": 1, "bonus": int(UpgradeManager.get_ship_stat("bullet_damage"))},
		"Cadencia": {"base": 0.2, "bonus": UpgradeManager.get_ship_stat("fire_rate"), "inverse": true}
	}
	
	for stat_name in stats.keys():
		var stat_data = stats[stat_name]
		_agregar_stat_row(stats_vbox, stat_name, stat_data)
	
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 1)
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	sep.add_theme_stylebox_override("separator", sep_style)
	stats_vbox.add_child(sep)
	
	var puntos_container := HBoxContainer.new()
	puntos_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_vbox.add_child(puntos_container)
	
	var puntos_icon := Label.new()
	puntos_icon.text = "◆"
	puntos_icon.add_theme_font_override("font", FONT)
	puntos_icon.add_theme_font_size_override("font_size", 24)
	puntos_icon.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	puntos_container.add_child(puntos_icon)
	
	var puntos_lbl := Label.new()
	puntos_lbl.text = " PUNTOS: %s" % _format_number(UpgradeManager.clicker_points)
	puntos_lbl.add_theme_font_override("font", FONT)
	puntos_lbl.add_theme_font_size_override("font_size", 28)
	puntos_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	puntos_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	puntos_lbl.add_theme_constant_override("outline_size", 2)
	puntos_container.add_child(puntos_lbl)

func _crear_stats_container() -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 0)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.35, 0.35, 0.7)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	margin.add_child(vbox)
	
	return {"panel": panel, "vbox": vbox}

func _agregar_stat_row(container: VBoxContainer, nombre: String, data: Dictionary) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 0)
	row.add_child(header)
	
	var name_lbl := Label.new()
	name_lbl.text = nombre.to_upper()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_override("font", FONT)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	header.add_child(name_lbl)
	
	var valor_final: String
	var bonus_text: String
	
	if data.get("inverse", false):
		var total = maxf(0.05, data.base - data.bonus)
		valor_final = "%.2fs" % total
		if data.bonus > 0:
			bonus_text = " (−%.2fs)" % data.bonus
		else:
			bonus_text = ""
	else:
		var total = data.base + data.bonus
		valor_final = _format_number(total) if total >= 1000 else str(total)
		if data.bonus > 0:
			bonus_text = " (+%s)" % _format_number(data.bonus)
		else:
			bonus_text = ""
	
	var valor_lbl := Label.new()
	valor_lbl.text = valor_final
	valor_lbl.add_theme_font_override("font", FONT)
	valor_lbl.add_theme_font_size_override("font_size", 26)
	valor_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	valor_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	valor_lbl.add_theme_constant_override("outline_size", 2)
	header.add_child(valor_lbl)
	
	if bonus_text != "":
		var bonus_lbl := Label.new()
		bonus_lbl.text = bonus_text
		bonus_lbl.add_theme_font_override("font", FONT)
		bonus_lbl.add_theme_font_size_override("font_size", 18)
		bonus_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5, 0.9))
		header.add_child(bonus_lbl)
	
	if data.bonus > 0 and not data.get("inverse", false):
		var bar_bg := ColorRect.new()
		bar_bg.custom_minimum_size = Vector2(0, 4)
		bar_bg.color = Color(0.15, 0.15, 0.15, 0.9)
		row.add_child(bar_bg)
		
		var bar_fill := ColorRect.new()
		var total = data.base + data.bonus
		var progress = clampf(float(data.bonus) / float(total), 0.0, 1.0)
		bar_fill.custom_minimum_size = Vector2(0, 4)
		bar_fill.size_flags_horizontal = Control.SIZE_FILL
		bar_fill.color = Color(0.7, 0.7, 0.7, 0.95)
		bar_bg.add_child(bar_fill)
		bar_fill.anchor_right = progress
	
	container.add_child(row)

func _format_number(num: int) -> String:
	if num >= 1_000_000:
		return "%.1fM" % (num / 1_000_000.0)
	elif num >= 1_000:
		return "%.1fK" % (num / 1_000.0)
	else:
		return str(num)

func _actualizar_stats_nucleo() -> void:
	pass

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL DE APUESTA
# ═══════════════════════════════════════════════════════════════════════════════

func _build_bet_panel() -> void:
	bet_panel = Control.new()
	bet_panel.name = "BetPanel"
	bet_panel.visible = false
	bet_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bet_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bet_panel)
	
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	bet_panel.add_child(overlay)
	
	var center_panel := PanelContainer.new()
	center_panel.set_anchors_preset(Control.PRESET_CENTER)
	center_panel.custom_minimum_size = Vector2(600, 400)
	center_panel.position = Vector2(-300, -200)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.18, 0.98)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.3, 0.6, 1.0, 0.9)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	center_panel.add_theme_stylebox_override("panel", style)
	bet_panel.add_child(center_panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	center_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	var title := Label.new()
	title.text = "INICIAR MISIÓN"
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var desc := Label.new()
	desc.text = "Apuesta puntos del nucleo para multiplicarlos\nSi completas el objetivo x2"
	desc.add_theme_font_override("font", FONT)
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	var sep := HSeparator.new()
	vbox.add_child(sep)
	
	var slider_container := VBoxContainer.new()
	slider_container.add_theme_constant_override("separation", 12)
	vbox.add_child(slider_container)
	
	bet_label = Label.new()
	bet_label.text = "0 puntos"
	bet_label.add_theme_font_override("font", FONT)
	bet_label.add_theme_font_size_override("font_size", 28)
	bet_label.add_theme_color_override("font_color", Color(1, 0.95, 0.3))
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slider_container.add_child(bet_label)
	
	bet_slider = HSlider.new()
	bet_slider.min_value = 0
	bet_slider.max_value = UpgradeManager.clicker_points
	bet_slider.step = 10
	bet_slider.value = 0
	bet_slider.custom_minimum_size = Vector2(0, 40)
	bet_slider.value_changed.connect(_on_bet_slider_changed)
	slider_container.add_child(bet_slider)
	
	bet_reward_label = Label.new()
	bet_reward_label.text = "Recompensa si ganas: 0 pts"
	bet_reward_label.add_theme_font_override("font", FONT)
	bet_reward_label.add_theme_font_size_override("font_size", 20)
	bet_reward_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	bet_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slider_container.add_child(bet_reward_label)
	
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)
	
	var btn_container := HBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 2)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_container)
	
	var cancel_btn := Button.new()
	cancel_btn.text = "CANCELAR"
	cancel_btn.custom_minimum_size = Vector2(200, 60)
	cancel_btn.add_theme_font_override("font", FONT)
	cancel_btn.add_theme_font_size_override("font_size", 24)
	cancel_btn.pressed.connect(_on_bet_cancel)
	btn_container.add_child(cancel_btn)
	
	var start_btn := Button.new()
	start_btn.text = "INICIAR MISIÓN"
	start_btn.custom_minimum_size = Vector2(200, 60)
	start_btn.add_theme_font_override("font", FONT)
	start_btn.add_theme_font_size_override("font_size", 24)
	start_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	start_btn.pressed.connect(_on_bet_start)
	btn_container.add_child(start_btn)

func _on_bet_slider_changed(value: float) -> void:
	var bet: int = int(value)
	bet_label.text = "Apuesta: %d puntos" % bet
	var reward: int = int(bet * UpgradeManager.bet_multiplier)
	bet_reward_label.text = "Recompensa si ganas: %d pts" % reward

func _on_bet_cancel() -> void:
	bet_panel.visible = false

func _on_bet_start() -> void:
	var bet_amount: int = int(bet_slider.value)
	if UpgradeManager.start_mission(bet_amount):
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_play_button_pressed():
	bet_slider.max_value = UpgradeManager.clicker_points
	bet_slider.value = min(bet_slider.value, UpgradeManager.clicker_points)
	_on_bet_slider_changed(bet_slider.value)
	bet_panel.visible = true

# ═══════════════════════════════════════════════════════════════════════════════

func _on_scroll_container_scroll_started() -> void:
	is_scrolling = true
	 
func _on_scroll_container_scroll_ended() -> void:
	is_scrolling = false
	was_scrolling = true
	
func _process(delta: float) -> void:
	var max_scroll: float = scroller.get_h_scroll_bar().max_value
	if max_scroll == 0:
		return
		
	elif was_scrolling:
		var progress: float = float(scroller.scroll_horizontal) / max_scroll
		var target: float = round(progress)
		scroll_pos = lerp(scroll_pos, max_scroll * target, 1.0 - pow(0.001, delta))
		scroller.scroll_horizontal = int(scroll_pos)
		var cb: float = animation_tree["parameters/blend_position"]
		animation_tree["parameters/blend_position"] = lerp(cb, target, 1.0 - pow(0.001, delta))
		if abs(scroll_pos - max_scroll * target) < 0.5:
			scroll_pos = max_scroll * target
			scroller.scroll_horizontal = int(scroll_pos)
			animation_tree["parameters/blend_position"] = target
			was_scrolling = false

	elif is_scrolling:
		scroll_pos = float(scroller.scroll_horizontal)
		animation_tree["parameters/blend_position"] = scroll_pos / max_scroll

func _on_button_pressed(extra_arg_0: int) -> void:
	var max_scroll: float = scroller.get_h_scroll_bar().max_value
	var target_scroll: float = max_scroll * float(extra_arg_0)
	var duration: float = 0.4

	if button_tween:
		button_tween.kill()
	button_tween = create_tween()
	button_tween.set_parallel(true)
	button_tween.set_trans(Tween.TRANS_SINE)
	button_tween.set_ease(Tween.EASE_IN_OUT)
	button_tween.tween_method(func(v: float): scroller.scroll_horizontal = int(v), float(scroller.scroll_horizontal), target_scroll, duration)
	button_tween.tween_property(animation_tree, "parameters/blend_position", float(extra_arg_0), duration)

func _on_mejoras_nave_btn_pressed() -> void:
	panel_mejoras.abrir("nave")
