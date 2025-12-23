extends Control

@export var base_points_per_click: int = 1
@export var click_scale_amount: float = 1.2
@export var click_scale_duration: float = 0.1

var auto_click_timer: float = 0.0

@onready var points_label = get_node_or_null("VBoxContainer/PointsLabel")
@onready var game_points_label = get_node_or_null("VBoxContainer/GamePointsLabel")
@onready var click_area = get_node_or_null("VBoxContainer/ClickArea")
@onready var upgrades_container = get_node_or_null("VBoxContainer/UpgradesContainer")
@onready var ship_upgrades_container = get_node_or_null("VBoxContainer/ShipUpgradesContainer")
@onready var clicker_upgrades_container = get_node_or_null("VBoxContainer/ClickerUpgradesContainer")

func _ready():
	setup_ui()
	connect_signals()
	update_ui()

func setup_ui():
	# Crear labels si no existen
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		add_child(vbox)
	
	if not points_label:
		points_label = Label.new()
		points_label.name = "PointsLabel"
		vbox.add_child(points_label)
		vbox.move_child(points_label, 0)
	
	if not game_points_label:
		game_points_label = Label.new()
		game_points_label.name = "GamePointsLabel"
		vbox.add_child(game_points_label)
		vbox.move_child(game_points_label, 1)
	
	# Configurar área de click
	if not click_area:
		click_area = TextureButton.new()
		click_area.name = "ClickArea"
		click_area.custom_minimum_size = Vector2(32, 32)
		click_area.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		click_area.texture_normal = load("res://assets/sprites/nave.png")
		vbox.add_child(click_area)
		vbox.move_child(click_area, 2)
	
	if click_area and not click_area.pressed.is_connected(_on_click_area_pressed):
		click_area.pressed.connect(_on_click_area_pressed)
	
	# Crear contenedores de upgrades
	if not ship_upgrades_container:
		var label = Label.new()
		label.text = "=== MEJORAS DE NAVE (con puntos clicker) ==="
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
		
		ship_upgrades_container = VBoxContainer.new()
		ship_upgrades_container.name = "ShipUpgradesContainer"
		vbox.add_child(ship_upgrades_container)
	
	if not clicker_upgrades_container:
		var label = Label.new()
		label.text = "=== MEJORAS DE CLICKER (con puntos de juego) ==="
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
		
		clicker_upgrades_container = VBoxContainer.new()
		clicker_upgrades_container.name = "ClickerUpgradesContainer"
		vbox.add_child(clicker_upgrades_container)
	
	setup_upgrade_buttons()

func connect_signals():
	if UpgradeManager:
		UpgradeManager.clicker_points_changed.connect(_on_points_changed)
		UpgradeManager.game_points_changed.connect(_on_game_points_changed)
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)

func setup_upgrade_buttons():
	# Limpiar upgrades anteriores
	for child in ship_upgrades_container.get_children():
		child.queue_free()
	for child in clicker_upgrades_container.get_children():
		child.queue_free()
	
	# Crear botones para mejoras de nave
	for upgrade_id in UpgradeManager.ship_upgrades.keys():
		var button = create_upgrade_button(upgrade_id, "ship")
		ship_upgrades_container.add_child(button)
	
	# Crear botones para mejoras de clicker
	for upgrade_id in UpgradeManager.clicker_upgrades.keys():
		var button = create_upgrade_button(upgrade_id, "clicker")
		clicker_upgrades_container.add_child(button)

func create_upgrade_button(upgrade_id: String, upgrade_type: String) -> Button:
	var button = Button.new()
	button.name = upgrade_id + "_button"
	button.set_meta("upgrade_id", upgrade_id)
	button.set_meta("upgrade_type", upgrade_type)
	
	if upgrade_type == "ship":
		button.pressed.connect(_on_ship_upgrade_pressed.bind(upgrade_id))
	else:
		button.pressed.connect(_on_clicker_upgrade_pressed.bind(upgrade_id))
	
	update_button_text(button)
	return button

func update_button_text(button: Button):
	var upgrade_id = button.get_meta("upgrade_id")
	var upgrade_type = button.get_meta("upgrade_type")
	
	var upgrade_data
	var cost
	var current_points
	
	if upgrade_type == "ship":
		upgrade_data = UpgradeManager.ship_upgrades[upgrade_id]
		cost = UpgradeManager.get_ship_upgrade_cost(upgrade_id)
		current_points = UpgradeManager.clicker_points
	else:
		upgrade_data = UpgradeManager.clicker_upgrades[upgrade_id]
		cost = UpgradeManager.get_clicker_upgrade_cost(upgrade_id)
		current_points = UpgradeManager.game_points
	
	var name_text = upgrade_id.replace("_", " ").capitalize()
	var level = upgrade_data["level"]
	var value = upgrade_data["value"]
	
	button.text = "%s Lv.%d (+%s) - %d pts" % [name_text, level, str(value), cost]
	button.disabled = current_points < cost

func _process(delta):
	# Auto-clicker
	var auto_speed = UpgradeManager.get_clicker_stat("auto_clicker_speed")
	if auto_speed > 0:
		auto_click_timer += delta
		var interval = 1.0 / auto_speed
		if auto_click_timer >= interval:
			auto_click_timer = 0.0
			perform_click(false)  # Sin animación para auto-click

func _on_click_area_pressed():
	perform_click(true)

func perform_click(with_animation: bool = true):
	var click_value = base_points_per_click + int(UpgradeManager.get_clicker_stat("points_per_click"))
	
	UpgradeManager.add_clicker_points(click_value)
	
	if with_animation:
		animate_click()
		spawn_click_effect(click_value)

func animate_click():
	if not click_area:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(click_area, "scale", Vector2.ONE * click_scale_amount, click_scale_duration)
	tween.tween_property(click_area, "scale", Vector2.ONE, click_scale_duration)

func spawn_click_effect(value: int):
	if not click_area:
		return
	
	var label = Label.new()
	label.text = "+" + str(value)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 1, 0))
	
	var pos = click_area.global_position + click_area.size / 2
	pos += Vector2(randf_range(-50, 50), randf_range(-50, 50))
	label.global_position = pos
	
	get_tree().root.add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 100, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)

func update_ui():
	if points_label:
		points_label.text = "Puntos Clicker: " + str(UpgradeManager.clicker_points)
	
	if game_points_label:
		game_points_label.text = "Puntos de Juego: " + str(UpgradeManager.game_points)
	
	# Actualizar todos los botones
	for button in ship_upgrades_container.get_children():
		if button is Button:
			update_button_text(button)
	
	for button in clicker_upgrades_container.get_children():
		if button is Button:
			update_button_text(button)

func _on_ship_upgrade_pressed(upgrade_id: String):
	if UpgradeManager.buy_ship_upgrade(upgrade_id):
		update_ui()

func _on_clicker_upgrade_pressed(upgrade_id: String):
	if UpgradeManager.buy_clicker_upgrade(upgrade_id):
		update_ui()

func _on_points_changed(_new_points: int):
	update_ui()

func _on_game_points_changed(_new_points: int):
	update_ui()

func _on_upgrade_purchased(_upgrade_type: String, _upgrade_id: String):
	update_ui()
