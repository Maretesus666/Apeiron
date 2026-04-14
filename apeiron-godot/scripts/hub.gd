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
	
	_mejorar_botones_nave()
	_actualizar_stats_nave()
	_actualizar_stats_nucleo()
	
	UpgradeManager.upgrade_purchased.connect(func(_t,_i): 
		_actualizar_stats_nave()
		_actualizar_stats_nucleo()
	)
	
	_build_bet_panel()

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
	
	# Paleta monocromática elegante
	var bg_normal := Color(0.12, 0.12, 0.12, 0.95)      # Gris muy oscuro
	var bg_hover := Color(0.22, 0.22, 0.22, 0.98)       # Gris oscuro
	var bg_pressed := Color(0.08, 0.08, 0.08, 1.0)      # Negro casi puro
	var border_normal := Color(0.45, 0.45, 0.45, 0.8)   # Gris medio
	var border_hover := Color(0.85, 0.85, 0.85, 0.95)   # Gris claro
	var border_pressed := Color(0.25, 0.25, 0.25, 0.9)  # Gris oscuro
	
	# Estado normal
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
	style_normal.shadow_color = Color(0, 0, 0, 0.4)
	style_normal.shadow_size = 4
	style_normal.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", style_normal)
	
	# Estado hover
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
	style_hover.shadow_color = Color(0, 0, 0, 0.5)
	style_hover.shadow_size = 6
	style_hover.shadow_offset = Vector2(0, 3)
	btn.add_theme_stylebox_override("hover", style_hover)
	
	# Estado pressed
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
	style_pressed.shadow_color = Color(0, 0, 0, 0.3)
	style_pressed.shadow_size = 2
	style_pressed.shadow_offset = Vector2(0, 1)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	
	# Colores de texto
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))          # Blanco suave
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))      # Blanco puro
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.85, 0.85, 1.0)) # Gris claro
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	btn.add_theme_constant_override("outline_size", 4)
	btn.custom_minimum_size = Vector2(0, 90)

func _actualizar_stats_nave() -> void:
	var lbl: Label = $ContenedorBotones/ScrollContainer/HBoxContainer/Nave/VBoxContainer/InfoLabel
	
	var vel_base: int = 6000
	var vel_bonus: int = int(UpgradeManager.get_ship_stat("max_speed"))
	var vel_total: int = vel_base + vel_bonus
	
	var vida_base: int = 5
	var vida_bonus: int = int(UpgradeManager.get_ship_stat("max_health"))
	var vida_total: int = vida_base + vida_bonus
	
	var cadencia_base: float = 0.2
	var cadencia_bonus: float = UpgradeManager.get_ship_stat("fire_rate")
	var cadencia_total: float = maxf(0.05, cadencia_base - cadencia_bonus)
	
	var dano_base: int = 1
	var dano_bonus: int = int(UpgradeManager.get_ship_stat("bullet_damage"))
	var dano_total: int = dano_base + dano_bonus
	
	lbl.text = "NAVE\n"
	lbl.text += "===================\n"
	lbl.text += "Velocidad: %d (+%d)\n" % [vel_total, vel_bonus]
	lbl.text += "Vida: %d (+%d)\n" % [vida_total, vida_bonus]
	lbl.text += "Dano: %d (+%d)\n" % [dano_total, dano_bonus]
	lbl.text += "Cadencia: %.2fs\n" % cadencia_total
	lbl.text += "===================\n"
	lbl.text += "Puntos: %d" % UpgradeManager.clicker_points

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
	
	# Overlay oscuro
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	bet_panel.add_child(overlay)
	
	# Panel central
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
	
	# Contenido
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	center_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	# Título
	var title := Label.new()
	title.text = "INICIAR MISIÓN"
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Descripción
	var desc := Label.new()
	desc.text = "Apuesta puntos clicker para multiplicarlos\nSi completas el objetivo: GANAS x2\nSi mueres: PIERDES TODO"
	desc.add_theme_font_override("font", FONT)
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	var sep := HSeparator.new()
	vbox.add_child(sep)
	
	# Slider de apuesta
	var slider_container := VBoxContainer.new()
	slider_container.add_theme_constant_override("separation", 12)
	vbox.add_child(slider_container)
	
	bet_label = Label.new()
	bet_label.text = "Apuesta: 0 puntos"
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
	
	# Botones
	var btn_container := HBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 20)
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
	# Actualizar slider con puntos actuales
	bet_slider.max_value = UpgradeManager.clicker_points
	bet_slider.value = min(bet_slider.value, UpgradeManager.clicker_points)
	_on_bet_slider_changed(bet_slider.value)
	
	# Mostrar panel de apuesta
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
