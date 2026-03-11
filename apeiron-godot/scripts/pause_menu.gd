extends CanvasLayer

@onready var pause_panel    := $Panel
@onready var title_label    := $Panel/VBoxContainer/TitleLabel
@onready var score_label    := $Panel/VBoxContainer/ScoreLabel
@onready var resume_button  := $Panel/VBoxContainer/ResumeButton
@onready var restart_button := $Panel/VBoxContainer/RestartButton
@onready var menu_button    := $Panel/VBoxContainer/MenuButton

var is_paused:    bool = false
var is_game_over: bool = false
var _mobile: Node = null

func _ready() -> void:
	hide_menu()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.player_died.connect(_on_player_died)
	# Buscar controles móviles
	await get_tree().process_frame
	_mobile = get_tree().get_first_node_in_group("mobile_controls")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not is_game_over:
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	if is_paused:
		_show_pause()
	else:
		_hide()

func _show_pause() -> void:
	pause_panel.visible  = true
	title_label.text     = "PAUSA"
	resume_button.visible = true
	get_tree().paused    = true
	# Deshabilitar controles móviles para que no bloqueen los botones
	if _mobile:
		_mobile.enabled = false

func show_game_over_menu(score: int = 0) -> void:
	is_game_over         = true
	pause_panel.visible  = true
	title_label.text     = "GAME OVER"
	score_label.text     = "Puntuación: %d" % score
	score_label.visible  = true
	resume_button.visible = false
	get_tree().paused    = true
	if _mobile:
		_mobile.enabled = false

func hide_menu() -> void:
	pause_panel.visible = false
	get_tree().paused   = false
	# Re-habilitar controles móviles al cerrar el menú
	if _mobile:
		_mobile.enabled = true

func _hide() -> void:
	hide_menu()

func _on_player_died() -> void:
	await get_tree().create_timer(1.0).timeout
	show_game_over_menu(ScoreManager.score if ScoreManager else 0)

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")
