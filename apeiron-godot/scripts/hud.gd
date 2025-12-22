extends CanvasLayer

@onready var health_label = $HealthContainer/HealthLabel
@onready var hearts_container = $HealthContainer/HeartsContainer
# Comentar temporalmente score si no existe el contenedor
# @onready var score_label = $ScoreContainer/ScoreLabel
# @onready var combo_label = $ScoreContainer/ComboLabel

var heart_full = "♥"
var heart_empty = "♡"

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
		_on_player_health_changed(player.current_health, player.max_health)
	
	# Conectar al ScoreManager solo si existe
	if has_node("ScoreContainer/ScoreLabel") and ScoreManager:
		var score_label = $ScoreContainer/ScoreLabel
		var combo_label = $ScoreContainer/ComboLabel
		ScoreManager.score_changed.connect(_on_score_changed)
		ScoreManager.combo_changed.connect(_on_combo_changed)
		_on_score_changed(ScoreManager.score)
		_on_combo_changed(ScoreManager.combo)

func _on_score_changed(new_score: int):
	if has_node("ScoreContainer/ScoreLabel"):
		var score_label = $ScoreContainer/ScoreLabel
		score_label.text = "Puntos: " + str(new_score)

func _on_combo_changed(new_combo: int):
	if has_node("ScoreContainer/ComboLabel"):
		var combo_label = $ScoreContainer/ComboLabel
		if new_combo > 1:
			combo_label.visible = true
			combo_label.text = "Combo x" + str(new_combo)
		else:
			combo_label.visible = false

func _on_player_health_changed(current_health: int, max_health: int):
	# Actualizar texto
	health_label.text = "VIDA: %d/%d" % [current_health, max_health]
	
	# Actualizar corazones
	update_hearts(current_health, max_health)

func update_hearts(current: int, maximum: int):
	if not hearts_container:
		return
	
	# Limpiar corazones anteriores
	for child in hearts_container.get_children():
		child.queue_free()
	
	# Crear nuevos corazones
	for i in range(maximum):
		var heart_label = Label.new()
		heart_label.add_theme_font_size_override("font_size", 32)
		
		if i < current:
			heart_label.text = heart_full
			heart_label.add_theme_color_override("font_color", Color(1, 0, 0))
		else:
			heart_label.text = heart_empty
			heart_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		
		hearts_container.add_child(heart_label)

func _on_player_died():
	# Mostrar mensaje de Game Over
	var game_over = Label.new()
	game_over.text = "GAME OVER"
	game_over.add_theme_font_size_override("font_size", 64)
	game_over.add_theme_color_override("font_color", Color(1, 0, 0))
	game_over.position = Vector2(
		get_viewport().size.x / 2 - 150,
		get_viewport().size.y / 2
	)
	add_child(game_over)
