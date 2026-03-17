extends CanvasLayer

const FONT := preload("res://assets/fonts/ultrakill.ttf")

@onready var health_label:     Label        = $HealthContainer/HealthLabel
@onready var hearts_container: HBoxContainer = $HealthContainer/HeartsContainer
@onready var score_label:      Label        = $ScoreContainer/ScoreLabel
@onready var combo_label:      Label        = $ScoreContainer/ComboLabel

var speed_container: Control
var speed_bar_bg:    ColorRect
var speed_bar_fill:  ColorRect
var speed_label:     Label
var speed_value:     Label
var boost_label:     Label

var fps_label: Label = null   # ← nuevo

var player: CharacterBody2D = null
var _display_speed: float   = 0.0
var _boost_timer:   float   = 0.0

const HEART_FULL  := "♥"
const HEART_EMPTY := "♡"

func _ready() -> void:
	_setup_existing_labels()
	_build_speed_hud()
	_build_fps_label()

	player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
		_on_player_health_changed(player.current_health, player.max_health)

	if ScoreManager:
		ScoreManager.score_changed.connect(_on_score_changed)
		ScoreManager.combo_changed.connect(_on_combo_changed)
		_on_score_changed(ScoreManager.score)
		_on_combo_changed(ScoreManager.combo)

	# Escuchar cambios de configuración en tiempo real
	ConfigManager.connect("mobile_controls_changed", func(_v): _build_fps_label())

func _setup_existing_labels() -> void:
	$HealthContainer.position = Vector2(10, 10)
	$ScoreContainer.position  = Vector2(10, 30)

	for lbl in [health_label, score_label, combo_label]:
		if lbl:
			lbl.add_theme_font_override("font", FONT)
			lbl.add_theme_font_size_override("font_size", 28)

	if combo_label:
		combo_label.visible = false
	if hearts_container:
		hearts_container.position.y += 50
	var sc := score_label.get_parent() if score_label else null
	if sc:
		sc.add_theme_constant_override("separation", 40)

func _build_speed_hud() -> void:
	var vp := get_viewport().get_visible_rect().size

	speed_container = Control.new()
	speed_container.name               = "SpeedHUD"
	speed_container.position           = Vector2(24, vp.y - 110)
	speed_container.custom_minimum_size = Vector2(220, 90)
	add_child(speed_container)

	speed_label = Label.new()
	speed_label.text     = "VEL"
	speed_label.position = Vector2(0, 0)
	speed_label.add_theme_font_override("font", FONT)
	speed_label.add_theme_font_size_override("font_size", 18)
	speed_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	speed_container.add_child(speed_label)

	speed_value = Label.new()
	speed_value.text     = "0"
	speed_value.position = Vector2(40, -2)
	speed_value.add_theme_font_override("font", FONT)
	speed_value.add_theme_font_size_override("font_size", 28)
	speed_value.add_theme_color_override("font_color", Color(1, 1, 1))
	speed_container.add_child(speed_value)

	speed_bar_bg = ColorRect.new()
	speed_bar_bg.position = Vector2(0, 32)
	speed_bar_bg.size     = Vector2(220, 10)
	speed_bar_bg.color    = Color(0.15, 0.15, 0.15, 0.85)
	speed_container.add_child(speed_bar_bg)

	speed_bar_fill = ColorRect.new()
	speed_bar_fill.position = Vector2(0, 32)
	speed_bar_fill.size     = Vector2(0, 10)
	speed_bar_fill.color    = Color(0.2, 0.7, 1.0)
	speed_container.add_child(speed_bar_fill)

	boost_label = Label.new()
	boost_label.text    = "▶ BOOST"
	boost_label.position = Vector2(0, 50)
	boost_label.add_theme_font_override("font", FONT)
	boost_label.add_theme_font_size_override("font_size", 22)
	boost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	boost_label.visible = false
	speed_container.add_child(boost_label)

# ─── FPS label — arriba a la izquierda, visible según config ─────────────────
func _build_fps_label() -> void:
	# Si ya existe lo destruimos para recrear con el estado actual
	if is_instance_valid(fps_label):
		fps_label.queue_free()
		fps_label = null

	if not ConfigManager.show_fps:
		return

	fps_label = Label.new()
	fps_label.name = "FPS_Label"
	fps_label.add_theme_font_override("font", FONT)
	fps_label.add_theme_font_size_override("font_size", 22)
	fps_label.add_theme_color_override("font_color", Color(1, 1, 0, 0.9))
	# Posición: arriba izquierda, debajo del health container
	fps_label.position = Vector2(10, 90)
	add_child(fps_label)

func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	_update_speed_hud(delta)
	# Actualizar FPS cada frame
	if is_instance_valid(fps_label):
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _update_speed_hud(delta: float) -> void:
	var real_speed: float = player.velocity.length()
	var max_spd: float    = player.max_speed if "max_speed" in player else 5000.0

	_display_speed = lerp(_display_speed, real_speed, 12.0 * delta)
	var fraction: float = clampf(_display_speed / max_spd, 0.0, 1.0)

	speed_value.text      = "%d" % int(_display_speed / 100.0)
	speed_bar_fill.size.x = 220.0 * fraction
	speed_bar_fill.color  = _speed_color(fraction)

	var boosting: bool = (
		Input.is_action_pressed("move_up") and
		Input.is_action_pressed("move_left") and
		Input.is_action_pressed("move_right")
	)
	if boosting:
		_boost_timer = 0.15
	if _boost_timer > 0.0:
		_boost_timer -= delta
		boost_label.visible = true
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.018)
		boost_label.modulate.a = 0.7 + 0.3 * pulse
	else:
		boost_label.visible = false

	if fraction > 0.85:
		var shake: float = (fraction - 0.85) / 0.15
		speed_value.position.x = 40.0 + randf_range(-shake * 2.0, shake * 2.0)
	else:
		speed_value.position.x = 40.0

func _speed_color(t: float) -> Color:
	if t < 0.5:
		return Color(0.2, 0.7, 1.0).lerp(Color(0.2, 1.0, 0.3), t * 2.0)
	elif t < 0.75:
		return Color(0.2, 1.0, 0.3).lerp(Color(1.0, 0.65, 0.1), (t - 0.5) * 4.0)
	else:
		return Color(1.0, 0.65, 0.1).lerp(Color(1.0, 0.1, 0.1), (t - 0.75) * 4.0)

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	health_label.text = "VIDA  %d / %d" % [current_health, max_health]
	_update_hearts(current_health, max_health)

func _update_hearts(current: int, maximum: int) -> void:
	hearts_container.add_theme_constant_override("separation", 8)
	for child in hearts_container.get_children():
		child.queue_free()
	for i in maximum:
		var lbl := Label.new()
		lbl.add_theme_font_override("font", FONT)
		lbl.add_theme_font_size_override("font_size", 30)
		if i < current:
			lbl.text = HEART_FULL
			lbl.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
		else:
			lbl.text = HEART_EMPTY
			lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
		hearts_container.add_child(lbl)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "PUNTOS  %d" % new_score

func _on_combo_changed(new_combo: int) -> void:
	if not combo_label:
		return
	if new_combo > 1:
		combo_label.visible = true
		combo_label.text    = "x%d COMBO" % new_combo
		combo_label.add_theme_color_override("font_color",
			Color(1.0, 1.0, 0.2) if new_combo < 5 else Color(1.0, 0.4, 0.1))
	else:
		combo_label.visible = false

func _on_player_died() -> void:
	var lbl := Label.new()
	lbl.text = "GAME OVER"
	lbl.add_theme_font_override("font", FONT)
	lbl.add_theme_font_size_override("font_size", 72)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.05, 0.05))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
