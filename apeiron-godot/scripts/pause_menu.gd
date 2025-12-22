extends CanvasLayer

# Cambiar los nombres para que coincidan con tu escena
@onready var pause_panel = $Panel  # ← CAMBIO: Tu nodo se llama Panel, no PausePanel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var score_label = $Panel/VBoxContainer/ScoreLabel
@onready var resume_button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button = $Panel/VBoxContainer/RestartButton
@onready var menu_button = $Panel/VBoxContainer/MenuButton

var is_paused = false
var is_game_over = false

func _ready():
	hide_menu()
	
	# Conectar al jugador
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.player_died.connect(_on_player_died)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not is_game_over:
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	
	if is_paused:
		show_pause_menu()
	else:
		hide_menu()

func show_pause_menu():
	pause_panel.visible = true
	title_label.text = "PAUSA"
	resume_button.visible = true
	get_tree().paused = true

func show_game_over_menu(score: int = 0):
	is_game_over = true
	pause_panel.visible = true
	title_label.text = "GAME OVER"
	score_label.text = "Puntuación: " + str(score)
	score_label.visible = true
	resume_button.visible = false
	get_tree().paused = true

func hide_menu():
	pause_panel.visible = false
	get_tree().paused = false

func _on_player_died():
	# Esperar un poco antes de mostrar game over
	await get_tree().create_timer(1.0).timeout
	show_game_over_menu()

func _on_resume_button_pressed():
	toggle_pause()

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")  # ← CAMBIO: Ir a Hub en vez de menu
