extends Control

@export var points_per_click: int = 1
@export var points_per_second: int = 0

var total_points: int = 0
var upgrades_data = {
	"auto_clicker": {"cost": 10, "level": 0, "points_per_sec": 1},
	"click_power": {"cost": 15, "level": 0, "bonus": 1},
	"super_auto": {"cost": 50, "level": 0, "points_per_sec": 5}
}

# Usar get_node para evitar errores si no existen los nodos
@onready var points_label = get_node_or_null("VBoxContainer/PointsLabel")
@onready var click_button = get_node_or_null("VBoxContainer/ClickButton")
@onready var start_game_button = get_node_or_null("VBoxContainer/StartGameButton")
@onready var upgrades_container = get_node_or_null("VBoxContainer/UpgradesContainer")

signal start_game_requested

func _ready():
	update_ui()
	setup_upgrades()
	
	# Conectar señales manualmente si existen
	if click_button:
		click_button.pressed.connect(_on_click_button_pressed)
	if start_game_button:
		start_game_button.pressed.connect(_on_start_game_button_pressed)

func _process(delta):
	if points_per_second > 0:
		total_points += int(points_per_second * delta)
		update_ui()

func _on_click_button_pressed():
	var click_value = points_per_click
	
	# Aplicar bonus de upgrade
	if upgrades_data["click_power"]["level"] > 0:
		click_value += upgrades_data["click_power"]["level"] * upgrades_data["click_power"]["bonus"]
	
	total_points += click_value
	update_ui()
	
	# Efecto visual
	spawn_click_effect()

func spawn_click_effect():
	if not click_button:
		return
		
	var label = Label.new()
	label.text = "+" + str(points_per_click)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 1, 0))
	
	var pos = click_button.global_position + Vector2(
		randf_range(-50, 50),
		randf_range(-50, 50)
	)
	label.global_position = pos
	get_parent().add_child(label)
	
	# Animación de subida y fade
	var tween = create_tween()
	tween.tween_property(label, "position:y", pos.y - 100, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func update_ui():
	if points_label:
		points_label.text = "Puntos: " + str(total_points)
	
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
		
		update_upgrade_button_text(button, upgrade_id)
		button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		
		upgrades_container.add_child(button)

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
		setup_upgrades()

func _on_start_game_button_pressed():
	start_game_requested.emit()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
