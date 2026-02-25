extends Control

@onready var panel       := $Panel
@onready var title_lbl   := $Panel/MarginContainer/VBoxContainer/HBoxContainer/TitleLabel
@onready var puntos_lbl  := $Panel/MarginContainer/VBoxContainer/PuntosSeparador
@onready var upgrades_vb := $Panel/MarginContainer/VBoxContainer/ScrollContainer/UpgradesVBox
@onready var cerrar_btn  := $Panel/MarginContainer/VBoxContainer/HBoxContainer/CloseBtn

const PANEL_X_ABIERTO := 660.0
const PANEL_X_CERRADO := 1080.0
var _tween: Tween
var _tipo_actual := ""

func _ready() -> void:
	cerrar_btn.pressed.connect(cerrar)
	$Overlay.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: cerrar()
	)
	panel.position.x = PANEL_X_CERRADO
	visible = false

func abrir(tipo: String) -> void:   # tipo: "nucleo" o "nave"
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
	_tween.tween_property(panel, "position:x", destino_x, 0.3)
	if ocultar_al_terminar:
		_tween.tween_callback(func(): visible = false)

func _poblar() -> void:
	# Limpiar
	for c in upgrades_vb.get_children():
		c.queue_free()

	if _tipo_actual == "nucleo":
		title_lbl.text = "MEJORAS NÚCLEO"
		puntos_lbl.text = "Puntos de juego: %d" % UpgradeManager.game_points
		for id in UpgradeManager.clicker_upgrades:
			upgrades_vb.add_child(_crear_boton(id, "clicker"))
	else:
		title_lbl.text = "MEJORAS NAVE"
		puntos_lbl.text = "Puntos clicker: %d" % UpgradeManager.clicker_points
		for id in UpgradeManager.ship_upgrades:
			upgrades_vb.add_child(_crear_boton(id, "ship"))

	# Refrescar puntos cuando cambien
	if not UpgradeManager.clicker_points_changed.is_connected(_on_puntos):
		UpgradeManager.clicker_points_changed.connect(_on_puntos)
	if not UpgradeManager.game_points_changed.is_connected(_on_puntos):
		UpgradeManager.game_points_changed.connect(_on_puntos)

func _on_puntos(_v) -> void:
	if visible:
		_poblar()

func _crear_boton(id: String, tipo: String) -> Button:
	var upgrades: Dictionary = UpgradeManager.clicker_upgrades if tipo == "clicker" else UpgradeManager.ship_upgrades
	var cost := UpgradeManager.get_clicker_upgrade_cost(id) if tipo == "clicker" \
				else UpgradeManager.get_ship_upgrade_cost(id)
	var pts  := UpgradeManager.game_points if tipo == "clicker" \
				else UpgradeManager.clicker_points

	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	btn.add_theme_font_override("font", load("res://assets/fonts/ultrakill.ttf"))
	btn.add_theme_font_size_override("font_size", 24)
	btn.disabled = pts < cost
	btn.text = _texto_boton(id, upgrades[id], cost)  # ← ESTA LÍNEA FALTABA

	btn.pressed.connect(func():
		var ok := UpgradeManager.buy_clicker_upgrade(id) if tipo == "clicker" \
				  else UpgradeManager.buy_ship_upgrade(id)
		if ok: _poblar()
	)
	return btn

func _texto_boton(id: String, u: Dictionary, cost: int) -> String:
	var nombre := id.replace("_", " ").capitalize()
	return "%s  Lv.%d\n+%s por nivel  ·  Costo: %d" % [nombre, u["level"], str(u["value"]), cost]
