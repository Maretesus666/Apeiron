extends PanelContainer

signal mejoras_solicitadas(tipo: String)

# — Config —
@export var rotation_speed: float = 0.3        
@export var click_scale_amount: float = 0.88    
@export var base_points_per_click: int = 1000 

# — Nodos creados en código —
var nucleo_sprite: TextureRect
var points_label: Label
var auto_click_timer: float = 0.0
var last_click_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_build_ui()
	UpgradeManager.clicker_points_changed.connect(_on_points_changed)

func _build_ui() -> void:
	# Margen exterior
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top",   24)
	margin.add_theme_constant_override("margin_bottom",24)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# — Label de puntos —
	points_label = Label.new()
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_label.add_theme_font_override("font", load("res://assets/fonts/ultrakill.ttf"))
	points_label.add_theme_font_size_override("font_size", 52)
	points_label.text = "Así como el infinito empieza"
	vbox.add_child(points_label)

	# — Centro: sprite clickeable —
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(center)

	# Control que actúa de pivot para la rotación
	var pivot := Control.new()
	pivot.custom_minimum_size = Vector2(280, 280)
	center.add_child(pivot)

	# TextureRect del núcleo
	nucleo_sprite = TextureRect.new()
	nucleo_sprite.texture = load("res://assets/sprites/nucleo (3).png")
	nucleo_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nucleo_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	nucleo_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nucleo_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	nucleo_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot.add_child(nucleo_sprite)

	# Botón invisible encima para capturar clicks
	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	btn.pressed.connect(_on_nucleo_clicked)
	btn.gui_input.connect(_on_nucleo_input)
	pivot.add_child(btn)

	# — Label "clickeame" debajo —
	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", load("res://assets/fonts/ultrakill.ttf"))
	hint.add_theme_font_size_override("font_size", 28)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	hint.text = "[ tocame el núcleo ]"
	vbox.add_child(hint)
	
	var btn_mejoras := Button.new()
	btn_mejoras.text = "MEJORAS NÚCLEO"
	btn_mejoras.add_theme_font_override("font", load("res://assets/fonts/ultrakill.ttf"))
	btn_mejoras.add_theme_font_size_override("font_size", 30) 
	vbox.add_child(btn_mejoras)
	btn_mejoras.pressed.connect(func(): mejoras_solicitadas.emit("nucleo"))

func _on_nucleo_input(event: InputEvent) -> void:
	# Capturar posición del click
	if event is InputEventMouseButton and event.pressed:
		last_click_pos = event.global_position
	elif event is InputEventScreenTouch and event.pressed:
		last_click_pos = event.position
	
func _process(delta: float) -> void:
	# Rotación lenta
	if nucleo_sprite:
		nucleo_sprite.pivot_offset = nucleo_sprite.size / 2.0
		nucleo_sprite.rotation += rotation_speed * delta

	# Auto-clicker
	var auto_speed := UpgradeManager.get_clicker_stat("auto_clicker_speed")
	if auto_speed > 0:
		auto_click_timer += delta
		if auto_click_timer >= 1.0 / auto_speed:
			auto_click_timer = 0.0
			_add_points(false, 0)

func _on_nucleo_clicked() -> void:
	# Bulk clicks
	var bulk := int(UpgradeManager.get_clicker_stat("bulk_clicks"))
	var times := 1 + bulk
	
	# Dispersar los números en círculo alrededor del click
	for i in times:
		_add_points(true, i)
	
	_animate_click()

func _add_points(show_fx: bool, offset_index: int = 0) -> void:
	var base_value := base_points_per_click + int(UpgradeManager.get_clicker_stat("points_per_click"))
	
	# Multiplicador
	var multiplier := 1.0 + UpgradeManager.get_clicker_stat("click_multiplier")
	
	# Combo bonus (usando el combo del ScoreManager)
	if ScoreManager:
		var combo_mult := 1.0 + (ScoreManager.combo * UpgradeManager.get_clicker_stat("combo_bonus"))
		multiplier *= combo_mult
	
	# Critical chance
	var crit_chance := UpgradeManager.get_clicker_stat("critical_chance")
	var is_critical := randf() * 100 < crit_chance
	
	if is_critical:
		var crit_mult := 2.0 + UpgradeManager.get_clicker_stat("critical_multiplier")
		multiplier *= crit_mult
	
	var final_value := int(base_value * multiplier)
	
	UpgradeManager.add_clicker_points(final_value)
	
	if show_fx:
		_spawn_float_label(final_value, offset_index)

func _animate_click() -> void:
	if not nucleo_sprite:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(nucleo_sprite, "scale", Vector2.ONE * click_scale_amount, 0.07)
	tween.tween_property(nucleo_sprite, "scale", Vector2.ONE, 0.12)

func _spawn_float_label(value: int, offset_index: int = 0) -> void:
	if not nucleo_sprite:
		return
		
	var lbl := Label.new()
	lbl.text = "+%d" % value
	lbl.add_theme_font_override("font", load("res://assets/fonts/ultrakill.ttf"))
	lbl.add_theme_font_size_override("font_size", 42)
	
	# Color RGB cíclico basado en el valor
	var color := _get_value_color(value)
	lbl.add_theme_color_override("font_color", color)
	
	# Outline para mejor visibilidad
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	
	# Posición en radio de 10 píxeles del último click
	# Para clicks múltiples, distribuir en círculo
	var angle := (TAU / maxf(1, UpgradeManager.get_clicker_stat("bulk_clicks") + 1)) * offset_index
	var radius := 50.0
	var offset := Vector2(cos(angle), sin(angle)) * radius
	
	# Usar posición del último click si está disponible, sino centro del sprite
	var base_pos: Vector2
	if last_click_pos != Vector2.ZERO:
		base_pos = last_click_pos
	else:
		base_pos = nucleo_sprite.global_position + nucleo_sprite.size / 2.0
	
	lbl.global_position = base_pos + offset
	
	get_tree().root.add_child(lbl)
	
	# Animación uniforme para todos
	var distance := 80.0
	var duration := 0.8
	
	var tw := lbl.create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - distance, duration)
	tw.tween_property(lbl, "modulate:a", 0.0, duration)
	
	tw.chain().tween_callback(lbl.queue_free)

# Genera un color RGB cíclico basado en el valor
func _get_value_color(value: int) -> Color:
	var position_in_cycle := fmod(float(value - 1), 10000.0) + 1.0
	var sqrt_value := sqrt(position_in_cycle)
	var sqrt_max := sqrt(10000.0)
	var hue := sqrt_value / sqrt_max
	var saturation := 1.0
	var value_brightness := 1.0
	return Color.from_hsv(hue, saturation, value_brightness)

func _on_points_changed(new_points: int) -> void:
	if points_label:
		# Formatear números grandes
		var text := ""
		if new_points >= 1_000_000:
			text = "%.2fM" % (new_points / 1_000_000.0)
		elif new_points >= 1_000:
			text = "%.1fK" % (new_points / 1_000.0)
		else:
			text = "%d" % new_points
		
		points_label.text = text
