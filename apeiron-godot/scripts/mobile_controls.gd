extends CanvasLayer

# ─── Config ───────────────────────────────────────────────────────────────────
@export var joystick_radius: float = 80.0
@export var knob_radius: float     = 36.0
@export var dead_zone: float       = 0.12

# ─── Estado público ───────────────────────────────────────────────────────────
var movement:    Vector2 = Vector2.ZERO
var joy_angle:   float   = 0.0
var joy_active:  bool    = false   # TRUE solo cuando el joystick está siendo usado
var shooting:    bool    = false

var enabled: bool = true:
	set(v):
		enabled = v
		_set_zones_active(v)

# ─── Internos ─────────────────────────────────────────────────────────────────
var _joy_touch_idx:   int     = -1
var _joy_origin:      Vector2 = Vector2.ZERO
var _shoot_touch_idx: int     = -1
var _knob_pos:        Vector2 = Vector2.ZERO
var _joy_visible:     bool    = false
var _shoot_pressed:   bool    = false

var _joy_zone:   Control
var _shoot_zone: Control
var _canvas:     Node2D

const FONT := preload("res://assets/fonts/ultrakill.ttf")
var _shoot_btn_pos: Vector2 = Vector2.ZERO
var _shoot_btn_r:   float   = 55.0
var _font_ref:      Font

func _ready() -> void:
	layer = 10
	add_to_group("mobile_controls")
	_font_ref = load("res://assets/fonts/ultrakill.ttf")
	enabled = ConfigManager.mobile_controls_enabled
	ConfigManager.mobile_controls_changed.connect(func(v: bool): enabled = v)

	var vp: Vector2 = get_viewport().get_visible_rect().size
	_shoot_btn_pos = Vector2(vp.x - _shoot_btn_r - 36, vp.y - _shoot_btn_r - 36)

	# Zona joystick (mitad izquierda)
	_joy_zone = Control.new()
	_joy_zone.position     = Vector2.ZERO
	_joy_zone.size         = Vector2(vp.x * 0.5, vp.y)
	_joy_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_joy_zone)
	_joy_zone.gui_input.connect(_on_joy_input)

	# Zona disparo (mitad derecha)
	_shoot_zone = Control.new()
	_shoot_zone.position     = Vector2(vp.x * 0.5, 0)
	_shoot_zone.size         = Vector2(vp.x * 0.5, vp.y)
	_shoot_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shoot_zone)
	_shoot_zone.gui_input.connect(_on_shoot_input)

	# Nodo de dibujo
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_on_canvas_draw)

func _process(_delta: float) -> void:
	_canvas.queue_redraw()

func _on_canvas_draw() -> void:
	# Joystick
	if _joy_visible:
		_canvas.draw_circle(_joy_origin, joystick_radius, Color(0.08, 0.08, 0.08, 0.50))
		_canvas.draw_arc(_joy_origin, joystick_radius, 0, TAU, 64, Color(1, 1, 1, 0.25), 2.5, true)
		_canvas.draw_line(
			_joy_origin + Vector2(-joystick_radius * 0.55, 0),
			_joy_origin + Vector2( joystick_radius * 0.55, 0),
			Color(1, 1, 1, 0.10), 1.5
		)
		_canvas.draw_line(
			_joy_origin + Vector2(0, -joystick_radius * 0.55),
			_joy_origin + Vector2(0,  joystick_radius * 0.55),
			Color(1, 1, 1, 0.10), 1.5
		)
		_canvas.draw_circle(_knob_pos, knob_radius, Color(1, 1, 1, 0.55))
		_canvas.draw_arc(_knob_pos, knob_radius, 0, TAU, 48, Color(1, 1, 1, 0.90), 2.5, true)

	# Botón FIRE
	var btn_color: Color = Color(1.0, 0.20, 0.20, 0.80) if _shoot_pressed else Color(0.75, 0.10, 0.10, 0.50)
	var rim_color: Color = Color(1.0, 0.50, 0.50, 0.70) if _shoot_pressed else Color(1.0, 0.35, 0.35, 0.45)
	_canvas.draw_circle(_shoot_btn_pos, _shoot_btn_r, btn_color)
	_canvas.draw_arc(_shoot_btn_pos, _shoot_btn_r, 0, TAU, 64, rim_color, 2.5, true)
	if _font_ref:
		var text := "FIRE"
		var fs   := 26
		var sw   := _font_ref.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_canvas.draw_string(
			_font_ref,
			_shoot_btn_pos + Vector2(-sw * 0.5, fs * 0.35),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			fs,
			Color(1, 1, 1, 0.95)
		)

# ─── Joystick input ───────────────────────────────────────────────────────────
func _on_joy_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _joy_touch_idx == -1:
			_joy_touch_idx = event.index
			_joy_origin    = event.position
			_knob_pos      = event.position
			_joy_visible   = true
		elif not event.pressed and event.index == _joy_touch_idx:
			_joy_touch_idx = -1
			_joy_visible   = false
			movement       = Vector2.ZERO
			joy_active     = false
	elif event is InputEventScreenDrag and event.index == _joy_touch_idx:
		_update_joystick(event.position)
	# Mouse para testear en PC
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _joy_touch_idx == -1:
			_joy_touch_idx = 0
			_joy_origin    = event.position
			_knob_pos      = event.position
			_joy_visible   = true
		elif not event.pressed and _joy_touch_idx == 0:
			_joy_touch_idx = -1
			_joy_visible   = false
			movement       = Vector2.ZERO
			joy_active     = false
	elif event is InputEventMouseMotion and _joy_touch_idx == 0:
		_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2) -> void:
	var delta: Vector2   = touch_pos - _joy_origin
	var dist: float      = delta.length()
	var clamped: Vector2 = delta.normalized() * minf(dist, joystick_radius)
	_knob_pos = _joy_origin + clamped

	var raw: Vector2 = clamped / joystick_radius
	if raw.length() < dead_zone:
		movement   = Vector2.ZERO
		joy_active = false
	else:
		var norm: Vector2 = (raw - raw.normalized() * dead_zone) / (1.0 - dead_zone)
		movement   = norm.limit_length(1.0)
		joy_angle  = raw.angle()   # ángulo real, sin valor centinela
		joy_active = true          # flag limpio para saber si está activo

# ─── Botón disparo input ──────────────────────────────────────────────────────
func _on_shoot_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _shoot_touch_idx == -1:
			_shoot_touch_idx = event.index
			shooting         = true
			_shoot_pressed   = true
		elif not event.pressed and event.index == _shoot_touch_idx:
			_shoot_touch_idx = -1
			shooting         = false
			_shoot_pressed   = false
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		shooting       = event.pressed
		_shoot_pressed = event.pressed

# ─── Habilitar / deshabilitar ─────────────────────────────────────────────────
func _set_zones_active(active: bool) -> void:
	if _joy_zone:
		_joy_zone.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	if _shoot_zone:
		_shoot_zone.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	if not active:
		movement         = Vector2.ZERO
		joy_active       = false
		shooting         = false
		_shoot_pressed   = false
		_joy_visible     = false
		_joy_touch_idx   = -1
		_shoot_touch_idx = -1
