extends Control

@export var points_per_click: int = 1
@export var points_per_second: int = 0
@export var click_scale_amount: float = 1.2  # Cuánto crece al clickear
@export var click_scale_duration: float = 0.1  # Duración de la animación

var total_points: int = 0
var upgrades_data = {
	"auto_clicker": {"cost": 10, "level": 0, "points_per_sec": 1},
	"click_power": {"cost": 15, "level": 0, "bonus": 1},
	"super_auto": {"cost": 50, "level": 0, "points_per_sec": 5}
}

@onready var points_label = get_node_or_null("VBoxContainer/PointsLabel")
@onready var click_area = get_node_or_null("VBoxContainer/ClickArea")
@onready var click_sprite = get_node_or_null("VBoxContainer/ClickArea/ClickSprite")
@onready var start_game_button = get_node_or_null("VBoxContainer/StartGameButton")
@onready var upgrades_container = get_node_or_null("VBoxContainer/UpgradesContainer")

signal start_game_requested

func _ready():
	setup_click_area()
	update_ui()
	setup_upgrades()
	
	if start_game_button:
		start_game_button.pressed.connect(_on_start_game_button_pressed)

func setup_click_area():
	# Si no existe el ClickArea, crearlo
	if not click_area:
		click_area = TextureButton.new()
		click_area.name = "ClickArea"
		click_area.custom_minimum_size = Vector2(250, 250)
		click_area.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		click_area.ignore_texture_size = true
		
		# Crear sprite si no existe
		if not click_sprite:
			# Usar la imagen de la nave como sprite clickeable
			var texture = load("res://assets/sprites/nave.png")
			click_area.texture_normal = texture
		
		# Añadir al VBoxContainer si existe
		var vbox = get_node_or_null("VBoxContainer")
		if vbox:
			# Insertar después de PointsLabel
			vbox.add_child(click_area)
			vbox.move_child(click_area, 1)
	
	# Conectar señal de click
	if click_area and not click_area.pressed.is_connected(_on_click_area_pressed):
		click_area.pressed.connect(_on_click_area_pressed)

func _process(delta):
	if points_per_second > 0:
		total_points += int(points_per_second * delta)
		update_ui()

func _on_click_area_pressed():
	var click_value = points_per_click
	
	# Aplicar bonus de upgrade
	if upgrades_data["click_power"]["level"] > 0:
		click_value += upgrades_data["click_power"]["level"] * upgrades_data["click_power"]["bonus"]
	
	total_points += click_value
	update_ui()
	
	# Animación del sprite
	animate_click()
	
	# Efecto visual de puntos
	spawn_click_effect(click_value)

func animate_click():
	if not click_area:
		return
	
	# Animación de escala
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	
	# Crecer
	tween.tween_property(click_area, "scale", Vector2.ONE * click_scale_amount, click_scale_duration)
	# Volver a normal
	tween.tween_property(click_area, "scale", Vector2.ONE, click_scale_duration)

func spawn_click_effect(value: int):
	if not click_area:
		return
		
	var label = Label.new()
	label.text = "+" + str(value)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1, 1, 0))
	
	# Posición aleatoria alrededor del sprite
	var pos = click_area.global_position + click_area.size / 2 + Vector2(
		randf_range(-100, 100),
		randf_range(-100, 100)
	)
	label.global_position = pos
	get_tree().root.add_child(label)
	
	# Animación de subida y fade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 150, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)

func update_ui():
	if points_label:
		points_label.text = "Puntos: " + str(total_points)
	
	# Actualizar botones de upgrade
	update_upgrade_buttons()
	
	# Actualizar visibilidad del botón de jugar
	if start_game_button:
		if total_points >= 100:
			start_game_button.visible = true
			start_game_button.text = "JUGAR (Gratis)"
		else:
			start_game_button.visible = false

func setup_upgrades():
	if not upgrades_container:
		return
		
	# Limpiar upgrades anteriores
	for child in upgrades_container.get_children():
		child.queue_free()
	
	# Crear botones de upgrade
	for upgrade_id in upgrades_data.keys():
		var upgrade = upgrades_data[upgrade_id]
		var button = Button.new()
		button.name = upgrade_id + "_button"
		
		update_upgrade_button_text(button, upgrade_id)
		button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		
		upgrades_container.add_child(button)

func update_upgrade_buttons():
	if not upgrades_container:
		return
	
	for child in upgrades_container.get_children():
		if child is Button:
			var upgrade_id = child.name.replace("_button", "")
			if upgrade_id in upgrades_data:
				update_upgrade_button_text(child, upgrade_id)

func update_upgrade_button_text(button: Button, upgrade_id: String):
	var upgrade = upgrades_data[upgrade_id]
	var cost = upgrade["cost"] * (upgrade["level"] + 1)
	
	var name_text = ""
	match upgrade_id:
		"auto_clicker":
			name_text = "Auto-Clicker"
		"click_power":
			name_text = "Poder de Click"
		"super_auto":
			name_text = "Super Auto"
	
	button.text = "%s Lv.%d - Costo: %d" % [name_text, upgrade["level"], cost]
	button.disabled = total_points < cost

func _on_upgrade_pressed(upgrade_id: String):
	var upgrade = upgrades_data[upgrade_id]
	var cost = upgrade["cost"] * (upgrade["level"] + 1)
	
	if total_points >= cost:
		total_points -= cost
		upgrade["level"] += 1
		
		# Aplicar efecto del upgrade
		match upgrade_id:
			"auto_clicker":
				points_per_second += upgrade["points_per_sec"]
			"super_auto":
				points_per_second += upgrade["points_per_sec"]
		
		update_ui()

func _on_start_game_button_pressed():
	start_game_requested.emit()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
